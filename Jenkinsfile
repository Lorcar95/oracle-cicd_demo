pipeline {
    agent any

    parameters {
        choice(
            name: 'GIT_BRANCH',
            choices: ['main', 'feature/add-task-priority'],
            description: 'Git branch to build'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: params.GIT_BRANCH,
                    credentialsId: 'github-read-token',
                    url: 'https://github.com/Lorcar95/oracle-cicd_demo.git'
            }
        }

        stage('Verify Source') {
            steps {
                sh '''
                    echo "Checking Oracle SQLcl Project..."
                    git log -1 --oneline
                    git branch --show-current
                    find src -type f | sort
                '''
            }
        }

        stage('Verify SQLcl') {
            steps {
                sh '''
                    echo "Checking SQLcl installation..."
                    sql -version
                '''
            }
        }
    }
}
