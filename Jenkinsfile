pipeline {
    // For this pattern, we start with a basic agent.
    // The real work will happen inside Docker containers defined in the stages.
    agent any

    environment {
        GCP_KEY_ID    = 'gcp-key'
        CONFIG_YML_ID = 'bq2pg-config-yml'
    }

    triggers {
        cron('H * * * *')
    }

    stages {
        stage('Build R Script Image') {
            // This stage runs on a temporary agent that has Docker.
            agent {
                docker {
                    image 'cheweych3w3y/jenkins-agent-with-docker:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock --group-add 281'
                }
            }
            steps {
                // First, checkout the code inside this agent
                checkout scm
                // Then, build the R script image
                script {
                    sh 'docker build -t ch3w3y/bq2pg-weather:latest -f Dockerfile .'
                }
            }
        }

        stage('Run ETL Task') {
            // This stage also runs on a temporary agent that has Docker.
            agent {
                docker {
                    image 'cheweych3w3y/jenkins-agent-with-docker:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock --group-add 281'
                }
            }
            steps {
                // THIS IS THE KEY: Use the .inside() block.
                // It starts the specified container and runs the closure inside it,
                // automatically mounting the workspace.
                docker.image('ch3w3y/bq2pg-weather:latest').inside {
                    // Now we are INSIDE the R script container.
                    // The workspace from the previous stage is automatically available.
                    withCredentials([
                        file(credentialsId: env.GCP_KEY_ID,    variable: 'GCP_KEY_PATH'),
                        file(credentialsId: env.CONFIG_YML_ID, variable: 'CONFIG_YML_PATH')
                    ]) {
                        // The secrets are available on the agent's filesystem.
                        // We need to copy them into a location INSIDE this container.
                        sh "mkdir -p /app/secrets"
                        sh "cp '${GCP_KEY_PATH}' /app/secrets/user.json"
                        sh "cp '${CONFIG_YML_PATH}' /app/secrets/config.yml"
                        
                        // Now, run the R script. It will find the files because
                        // we just copied them into the correct location inside this container.
                        sh "Rscript /app/data_transfer.R"
                    }
                }
            }
        }
    } // End of stages

    post {
        always {
            // This post action needs an agent context to run 'docker rmi'
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
    } // End of post

} // End of pipeline