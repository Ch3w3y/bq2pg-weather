pipeline {
  agent any

  environment {
    // These two must be created in Jenkins Credentials as "Secret file"
    GCP_KEY_ID    = 'gcp-key'          // your service-account.json
    CONFIG_YML_ID = 'bq2pg-config-yml' // your real config.yml
  }

  triggers {
    cron('0 * * * *')  // hourly at minute 0
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker image') {
      steps {
        script {
          // tags: ch3w3y/bq2pg-weather:latest
          docker.build("ch3w3y/bq2pg-weather:latest")
        }
      }
    }

    stage('Inject secrets') {
      steps {
        // bring your two secret files into the workspace
        withCredentials([
          file(credentialsId: env.GCP_KEY_ID,    variable: 'GCP_KEY_PATH'),
          file(credentialsId: env.CONFIG_YML_ID, variable: 'CONFIG_YML_PATH')
        ]) {
          sh '''
            cp "$GCP_KEY_PATH"        ./service-account.json
            cp "$CONFIG_YML_PATH"     ./config.yml
          '''
        }
      }
    }

    stage('Run ETL in container') {
      steps {
        script {
          // run the container, mounting the workspace into /app by default
          docker.image("ch3w3y/bq2pg-weather:latest").inside(
            // ensure the container sees the key and config
            "-e GOOGLE_APPLICATION_CREDENTIALS=/app/user.json"
          ) {
            // our script reads config.yml from /app/config.yml
            sh "Rscript /app/data_transfer.R"
          }
        }
      }
    }
  }

  post {
    success {
      echo "ETL completed successfully"
    }
    failure {
      echo "ETL FAILED – see Jenkins logs"
      // optional: mail, Slack, etc.
    }
  }
}