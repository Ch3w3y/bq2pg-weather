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
                // This makes their paths available in environment variables.
                withCredentials([
                    file(credentialsId: env.GCP_KEY_ID,    variable: 'GCP_KEY_PATH'),
                    file(credentialsId: env.CONFIG_YML_ID, variable: 'CONFIG_YML_PATH')
                ]) {
                    // This 'docker run' command is executed by the main agent.
                    // It starts your R script container with the secrets mounted.
                    sh '''
                        docker run --rm \
                          -v "${GCP_KEY_PATH}":/app/secrets/user.json:ro \
                          -v "${CONFIG_YML_PATH}":/app/secrets/config.yml:ro \
                          -e GOOGLE_APPLICATION_CREDENTIALS=/app/user.json \
                          ch3w3y/bq2pg-weather:latest
                    '''
                }
            }
        }
    } // End of stages

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