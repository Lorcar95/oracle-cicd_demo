
pipeline {
    agent any

    parameters {
        choice(
            name: 'GIT_BRANCH',
            choices: ['main', 'feature/add-task-priority'],
            description: 'Git branch to build'
        )

        string(
            name: 'RELEASE_VERSION',
            defaultValue: '1.0',
            description: 'Oracle release version'
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
                    set -e
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
                    set -e
                    echo "Checking SQLcl installation..."
                    sql -version
                '''
            }
        }

        stage('Prepare Git Branches') {
            steps {
                sh '''
                    set -e
                    echo "Preparing main branch..."

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
                        set -e

                        echo "Generating Liquibase changesets..."

                        rm -rf dist artifact

                        printf 'project stage -branch-name main -verbose\\nexit\\n' |
                        sql -S -L \
                            -user "$DB_USER" \
                            -password "$DB_PASSWORD" \
                            -url "jdbc:oracle:thin:@//local-26ai:1521/FREEPDB1"

                        test -f dist/releases/next/release.changelog.xml

                        echo "Generated changesets:"
                        find dist -type f | sort
                    '''
                }
            }
        }

        stage('Create Versioned Release') {
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
                        set -e

                        echo "Creating release ${RELEASE_VERSION}..."

                        printf 'project release -version %s -verbose\\nexit\\n' "$RELEASE_VERSION" |
                        sql -S -L \
                            -user "$DB_USER" \
                            -password "$DB_PASSWORD" \
                            -url "jdbc:oracle:thin:@//local-26ai:1521/FREEPDB1"

                        test -f "dist/releases/${RELEASE_VERSION}/release.changelog.xml"

                        echo "Release created successfully."
                    '''
                }
            }
        }

        stage('Generate ZIP Artifact') {
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
                        set -e

                        echo "Generating deployment ZIP..."

                        printf 'project gen-artifact -name R1 -version %s -format zip -verbose\\nexit\\n' "$BUILD_NUMBER" |
                        sql -S -L \
                            -user "$DB_USER" \
                            -password "$DB_PASSWORD" \
                            -url "jdbc:oracle:thin:@//local-26ai:1521/FREEPDB1"

                        test -f "artifact/R1-${BUILD_NUMBER}.zip"

                        echo "Generated deployment artifact:"
                        ls -lh "artifact/R1-${BUILD_NUMBER}.zip"

                        echo "ZIP contents:"
                        unzip -l "artifact/R1-${BUILD_NUMBER}.zip"
                    '''
                }
            }
        }

        stage('Archive Artifacts') {
            when {
                expression { params.GIT_BRANCH != 'main' }
            }
            steps {
                archiveArtifacts(
                    artifacts: 'dist/**/*,artifact/*.zip',
                    fingerprint: true
                )
            }
        }
    }
}
