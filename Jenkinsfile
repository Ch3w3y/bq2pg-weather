pipeline {
    // We will define the agent for each stage, so we start with 'agent none'
    agent none

    environment {
        GCP_KEY_ID    = 'gcp-key'
        CONFIG_YML_ID = 'bq2pg-config-yml'
    }

    triggers {
        cron('H * * * *')
    }

    stages {
        // This stage builds the R script image. It needs a Docker-capable agent.
        stage('Build R Script Image') {
            agent {
                docker {
                    image 'cheweych3w3y/jenkins-agent-with-docker:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock --group-add 281'
                }
            }
            steps {
                checkout scm
                script {
                    sh 'docker build -t ch3w3y/bq2pg-weather:latest -f Dockerfile .'
                }
            }
        }

        // This stage runs the ETL task. It also needs a Docker-capable agent.
        stage('Run ETL Task') {
            agent {
                docker {
                    image 'cheweych3w3y/jenkins-agent-with-docker:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock --group-add 281'
                }
            }
            steps {
                // THIS IS THE CRITICAL SYNTAX FIX:
                // The 'docker.image.inside' step must be wrapped in a 'script' block
                // to be used inside a Declarative stage.
                script {
                    docker.image('ch3w3y/bq2pg-weather:latest').inside {
                        // Now we are INSIDE the R script container.
                        withCredentials([
                            file(credentialsId: env.GCP_KEY_ID,    variable: 'GCP_KEY_PATH'),
                            file(credentialsId: env.CONFIG_YML_ID, variable: 'CONFIG_YML_PATH')
                        ]) {
                            // Copy the secrets from the agent's temp location
                            // to a known location inside this R container.
                            sh "mkdir -p /app/secrets"
                            sh "cp '${GCP_KEY_PATH}' /app/secrets/user.json"
                            sh "cp '${CONFIG_YML_PATH}' /app/secrets/config.yml"
                            
                            // Now, run the R script.
                            sh "Rscript /app/data_transfer.R"
                        }
                    }
                }
            }
        }
    } // End of stages

    // The 'post' block runs after all stages are complete.
    // It will automatically run on the agent from the last stage.
    post {
        always {
            // We don't need to define an agent here.
            // This will run on the 'cheweych3w3y/jenkins-agent-with-docker' agent.
            echo 'Cleaning up Docker image...'
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