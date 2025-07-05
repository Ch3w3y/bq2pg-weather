pipeline {
  // run this pipeline on any available agent
  agent {
        docker {
            image 'cheweych3w3y/jenkins-agent-with-docker:latest'
            // Mount the host's Docker socket into the container
            // This allows the agent to run docker commands against the host's daemon
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }

  // make our two secret-file credentials available
  environment {
    GCP_KEY_ID    = 'gcp-key'
    CONFIG_YML_ID = 'bq2pg-config-yml'
  }

  // schedule: every hour on the hour
  triggers {
    cron('H * * * *')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    // This stage *builds* your Docker image and tags it
    stage('Build Image') {
      steps {
        script {
          // requires Docker Pipeline plugin
          docker.build(
            'ch3w3y/bq2pg-weather:latest',
            '-f Dockerfile .'
          )
        }
      }
    }

    // This stage runs your ETL inside that image
    stage('Run ETL') {
      // launch the container with the two secret files mounted
      agent {
        docker {
          image 'ch3w3y/bq2pg-weather:latest'
          args  '''
            -v ${GCP_KEY_PATH}:/app/user.json:ro
            -v ${CONFIG_YML_PATH}:/app/config.yml:ro
            -e GOOGLE_APPLICATION_CREDENTIALS=/app/user.json
          '''
        }
      }
      steps {
        // expose the injected file paths
        withCredentials([
          file(credentialsId: env.GCP_KEY_ID,    variable: 'GCP_KEY_PATH'),
          file(credentialsId: env.CONFIG_YML_ID, variable: 'CONFIG_YML_PATH')
        ]) {
          sh '''
            Rscript /app/data_transfer.R
          '''
        }
      }
    }
  }

  post {
    success { echo '✅ ETL completed successfully' }
    failure { echo '‼️ ETL failed – check the logs above' }
  }
  
  
  
}