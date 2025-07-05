pipeline {
    // This is the main agent for the entire pipeline.
    // It has the Docker CLI and access to the host's Docker daemon.
    agent {
        docker {
            image 'cheweych3w3y/jenkins-agent-with-docker:latest'
            args '-v /var/run/docker.sock:/var/run/docker.sock --group-add 281'
        }
    }

    // Make your Jenkins credential IDs available as environment variables
    environment {
        GCP_KEY_ID    = 'gcp-key'
        CONFIG_YML_ID = 'bq2pg-config-yml'
    }

    // Trigger the pipeline to run hourly
    triggers {
        cron('H * * * *')
    }

    stages {
        // Stage 1: Get the source code
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        // Stage 2: Build the Docker image for your R script
        stage('Build R Script Image') {
            steps {
                script {
                    // This command is run by the main agent
                    sh 'docker build -t ch3w3y/bq2pg-weather:latest -f Dockerfile .'
                }
            }
        }

                // Stage 3: Run the R script container as a one-off task
        stage('Run ETL Task') {
            steps {
                // Use withCredentials to securely access your secret files.
                withCredentials([
                    file(credentialsId: env.GCP_KEY_ID,    variable: 'GCP_KEY_PATH'),
                    file(credentialsId: env.CONFIG_YML_ID, variable: 'CONFIG_YML_PATH')
                ]) {
                    // Use a script block for more complex logic
                    script {
                        // Define the path for our temporary secrets directory within the agent's workspace
                        def secretsDir = "${env.WORKSPACE}/temp_secrets"
                        
                        try {
                            // 1. Create a clean, temporary directory on the agent
                            sh "mkdir -p ${secretsDir}"
                            
                            // 2. Copy the secret files from their secure temp location into our new directory
                            sh "cp '${GCP_KEY_PATH}' '${secretsDir}/user.json'"
                            sh "cp '${CONFIG_YML_PATH}' '${secretsDir}/config.yml'"
                            
                            // 3. Run the container, mounting the ENTIRE directory.
                            //    This is a much more reliable operation than mounting single files.
                            sh """
                                docker run --rm \\
                                  -v "${secretsDir}":/app/secrets:ro \\
                                  -e GOOGLE_APPLICATION_CREDENTIALS=/app/secrets/user.json \\
                                  ch3w3y/bq2pg-weather:latest
                            """
                        } finally {
                            // 4. ALWAYS clean up the temporary secrets directory afterwards
                            echo "Cleaning up temporary secrets directory..."
                            sh "rm -rf ${secretsDir}"
                        }
                    }
                }
            }
        }

    // The 'post' section runs after the pipeline is complete
    post {
        always {
            // It's good practice to clean up the image you built to save disk space
            echo 'Cleaning up Docker image...'
            // Use -f to force removal even if a container is somehow left running
            sh 'docker rmi -f ch3w3y/bq2pg-weather:latest || true'
        }
        success {
            echo '✅ ETL completed successfully'
        }
        failure {
            echo '‼️ ETL failed – check the logs above'
        }
    } // End of post

} // End of pipeline