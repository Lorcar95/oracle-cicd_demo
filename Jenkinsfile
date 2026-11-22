
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

        stage('Prepare Git Branches') {
            steps {
                sh '''
                    echo "Preparing main branch for SQLcl comparison..."

                    git branch -f main origin/main

                    echo "Available branches:"
                    git branch -a

                    echo "Comparing changes:"
                    git diff --name-status main...HEAD -- src/
                '''
            }
        }

        stage('Generate Liquibase Changesets') {
            when {
                expression { params.GIT_BRANCH != 'main' }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'oracle-dev-credentials',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASSWORD'
                    )
                ]) {
                    sh '''
                        set +x

                        echo "Generating Liquibase changesets..."

                        rm -rf dist

                        printf 'project stage -branch-name main -verbose\\nexit\\n' |
                        sql -S -L \
                            -user "$DB_USER" \
                            -password "$DB_PASSWORD" \
                            -url "jdbc:oracle:thin:@//local-26ai:1521/FREEPDB1"

                        test -f dist/releases/next/release.changelog.xml

                        echo "Generated files:"
                        find dist -type f | sort
                    '''
                }
            }
        }

        stage('Archive Changesets') {
            when {
                expression { params.GIT_BRANCH != 'main' }
            }
            steps {
                archiveArtifacts artifacts: 'dist/**/*',
                                 fingerprint: true
            }
        }
    }
}
