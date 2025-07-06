pipeline {
    // We define the agent once for the entire pipeline.
    // This is simpler and avoids repeating the agent definition.
    agent {
        docker {
            image 'cheweych3w3y/jenkins-agent-with-docker:latest'
            args '-v /var/run/docker.sock:/var/run/docker.sock --group-add 281'
        }
    }

    environment {
        GCP_KEY_ID    = 'gcp-key'
        CONFIG_YML_ID = 'bq2pg-config-yml'
    }

    triggers {
        cron('H * * * *')
    }

    stages {
        // We will combine all the work into a single stage for clarity.
        stage('Build and Run ETL') {
            steps {
                // Use a script block to allow for try...finally logic.
                script {
                    try {
                        // --- STEP 1: CHECKOUT CODE ---
                        echo 'Checking out source code...'
                        checkout scm

                        // --- STEP 2: BUILD R SCRIPT IMAGE ---
                        echo 'Building R script Docker image...'
                        sh 'docker build -t ch3w3y/bq2pg-weather:latest -f Dockerfile .'

                        // --- STEP 3: RUN ETL TASK ---
                        echo 'Running ETL task...'
                        docker.image('ch3w3y/bq2pg-weather:latest').inside('--user root') {
                            withCredentials([
                                file(credentialsId: env.GCP_KEY_ID,    variable: 'GCP_KEY_PATH'),
                                file(credentialsId: env.CONFIG_YML_ID, variable: 'CONFIG_YML_PATH')
                            ]) {
                                sh "mkdir -p /app/secrets"
                                sh "cp '${GCP_KEY_PATH}' /app/secrets/user.json"
                                sh "cp '${CONFIG_YML_PATH}' /app/secrets/config.yml"
                                sh "chmod 644 /app/secrets/*"
                                
                                sh "Rscript /app/data_transfer.R"
                            }
                        }
                        
                        // If we reach here, the ETL was successful.
                        echo '✅ ETL completed successfully'

                    } catch (e) {
                        // If any step in the 'try' block fails, this will run.
                        echo '‼️ ETL failed – check the logs above'
                        // Re-throw the error to make the pipeline fail.
                        throw e
                    } finally {
                        // THIS BLOCK IS GUARANTEED TO RUN, ALWAYS.
                        // This is the correct place for cleanup.
                        echo 'Cleaning up Docker image...'
                        sh 'docker rmi -f ch3w3y/bq2pg-weather:latest || true'
                    }
                }
            }
        }
    } // End of stages
} // End of pipeline