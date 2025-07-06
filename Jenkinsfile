pipeline {
    // We will define the agent for each stage and for the post block.
    agent none

    environment {
        GCP_KEY_ID    = 'gcp-key'
        CONFIG_YML_ID = 'bq2pg-config-yml'
    }

    triggers {
        cron('H * * * *')
    }

    stages {
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

        stage('Run ETL Task') {
            agent {
                docker {
                    image 'cheweych3w3y/jenkins-agent-with-docker:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock --group-add 281'
                }
            }
            steps {
                script {
                    // THIS IS FIX #1: Add '--user root' to run the commands as the root user
                    // inside the R container, which has permission to write to /app.
                    docker.image('ch3w3y/bq2pg-weather:latest').inside('--user root') {
                        withCredentials([
                            file(credentialsId: env.GCP_KEY_ID,    variable: 'GCP_KEY_PATH'),
                            file(credentialsId: env.CONFIG_YML_ID, variable: 'CONFIG_YML_PATH')
                        ]) {
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

    post {
        always {
            // THIS IS FIX #2: Provide an agent for the post-build actions.
            // This ensures the 'docker rmi' command has a context to run in.
            agent {
                docker {
                    image 'cheweych3w3y/jenkins-agent-with-docker:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock --group-add 281'
                }
            }
            steps {
                echo 'Cleaning up Docker image...'
                sh 'docker rmi -f ch3w3y/bq2pg-weather:latest || true'
            }
        }
        success {
            echo '✅ ETL completed successfully'
        }
        failure {
            echo '‼️ ETL failed – check the logs above'
        }
    } // End of post

} // End of pipeline