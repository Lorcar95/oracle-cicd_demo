
pipeline {
    agent any

    parameters {
        string(
            name: 'GIT_BRANCH',
            defaultValue: 'feature/add-task-priority',
            description: 'Git branch to build',
            trim: true
        )
        string(
            name: 'RELEASE_VERSION',
            defaultValue: '1.0',
            description: 'Oracle release version'
        )
    }

    options {
        skipDefaultCheckout(true)
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                git(
                    branch: params.GIT_BRANCH,
                    credentialsId: 'github-read-token',
                    url: 'https://github.com/Lorcar95/oracle-cicd_demo.git'
                )
            }
        }

        stage('Verify Source') {
            steps {
                sh '''
                    set -eu
                    echo "Current commit:"
                    git log -1 --oneline

                    echo "Current branch:"
                    git branch --show-current

                    echo "Database source files:"
                    find src -type f | head -50
                '''
            }
        }

        stage('Verify SQLcl') {
            steps {
                sh '''
                    set -eu
                    sql -version
                '''
            }
        }

        stage('Prepare Git Branches') {
            steps {
                sh '''
                    set -eu

                    if [ "$(git branch --show-current)" != "main" ]; then
                        git branch -f main origin/main
                    fi
                    
                    git diff --name-status main...HEAD -- src/
                '''
            }
        }

        stage('Code Linting') {
            steps {
                sh '''
                    set -eu

                    sqlfluff --version

                    git show main:.sqlfluff > /tmp/sqlfluff-ci-config

                    git diff --name-only --diff-filter=AM -z main...HEAD \
                        -- src/database/cicd_dev/tables/ src/custom/ |
                        xargs -0 -r sqlfluff lint --config /tmp/sqlfluff-ci-config

                    echo "Code linting completed successfully."
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
                        set -eu

                        rm -rf dist artifact

                        printf 'project stage -branch-name main -verbose\\nexit\\n' |
                            sql -S -L \
                                -user "$DB_USER" \
                                -password "$DB_PASSWORD" \
                                -url "jdbc:oracle:thin:@//local-26ai:1521/FREEPDB1"


                        echo "Liquibase changesets generated successfully."
                    '''
                }
            }
        }

        stage('Process Custom SQL Scripts') {
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
                        set -eu
                        export LC_ALL=C
                        branch=$(git branch --show-current)
                        stage_dir="dist/releases/next/changes/$branch"
                        list=$(mktemp)
                        trap 'rm -f "$list"' EXIT

                        git diff --no-renames --name-only --diff-filter=MDT main...HEAD -- src/custom/ > "$list"
                        if [ -s "$list" ]; then
                            echo "Existing custom migrations must not be modified or deleted."
                            exit 1
                        fi
                        git diff --no-renames --name-only --diff-filter=A main...HEAD -- src/custom/ > "$list"
                        sort -o "$list" "$list"
                        while IFS= read -r source; do
                            name=${source#src/custom/}
                            case "$name" in
                                ''|*[!a-zA-Z0-9_.-]*|.*|-*) echo "Invalid migration filename: $source"; exit 1 ;;
                            esac
                            case "$name" in
                                *.sql) ;;
                                *) echo "Only SQL migrations are supported: $source"; exit 1 ;;
                            esac
                            target="$stage_dir/_custom/$name"
                            test ! -e "$target"
                            printf 'project stage add-custom -file-name %s -changelog STAGE -verbose\\nexit\\n' "$name" |
                                sql -S -L -user "$DB_USER" -password "$DB_PASSWORD" \
                                    -url "jdbc:oracle:thin:@//local-26ai:1521/FREEPDB1"
                            test -f "$target"
                            grep -Eq '^-- changeset +SqlCl:[0-9]+' "$target"
                            sed -i -E "s|^(-- changeset +)SqlCl:[0-9]+(.*) logicalFilePath:[^ ]+|\\1SqlCl:$name\\2 logicalFilePath:src/custom/$name|" "$target"
                            grep -F "SqlCl:$name " "$target"
                            grep -F "logicalFilePath:src/custom/$name" "$target"
                            printf '\\n' >> "$target"
                            cat "$source" >> "$target"
                            printf '\\n' >> "$target"
                            grep -F "_custom/$name" "$stage_dir/stage.changelog.xml"
                        done < "$list"
                        test -f dist/releases/next/release.changelog.xml
                        echo "Custom SQL processing completed successfully."
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
                        set -eu

                        test -n "$RELEASE_VERSION"

                        printf 'project release -version %s -verbose\\nexit\\n' "$RELEASE_VERSION" |
                            sql -S -L \
                                -user "$DB_USER" \
                                -password "$DB_PASSWORD" \
                                -url "jdbc:oracle:thin:@//local-26ai:1521/FREEPDB1"

                        test -f "dist/releases/${RELEASE_VERSION}/release.changelog.xml"

                        echo "Versioned release created successfully."
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
                        set -eu

                        printf 'project gen-artifact -name R1 -version %s -format zip -verbose\\nexit\\n' "$BUILD_NUMBER" |
                            sql -S -L \
                                -user "$DB_USER" \
                                -password "$DB_PASSWORD" \
                                -url "jdbc:oracle:thin:@//local-26ai:1521/FREEPDB1"

                        ZIP="artifact/R1-${BUILD_NUMBER}.zip"

                        test -f "$ZIP"

                        echo "Generated deployment artifact:"
                        ls -lh "$ZIP"

                        echo "ZIP contents:"
                        unzip -l "$ZIP"
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

        stage('Publish GitHub Prerelease') {
            when {
                expression { params.GIT_BRANCH != 'main' }
            }
            steps {
                script {
                    def tag = "ci-${env.BUILD_NUMBER}"
                    def zipName = "R1-${env.BUILD_NUMBER}.zip"

                    def commit = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()

                    def payload = groovy.json.JsonOutput.toJson([
                        tag_name: tag,
                        target_commitish: commit,
                        name: "Oracle CI Build ${env.BUILD_NUMBER}",
                        body: """Automated Oracle SQLcl deployment package.

Release version: ${params.RELEASE_VERSION}
Source branch: ${params.GIT_BRANCH}
Source commit: ${commit}
Artifact: ${zipName}

Status: Requires independent review and approval before deployment to Test.

This prerelease does not deploy database changes.""",
                        draft: false,
                        prerelease: true
                    ])

                    writeFile(
                        file: 'github-release.json',
                        text: payload
                    )

                    withCredentials([
                        string(
                            credentialsId: 'github-release-token',
                            variable: 'GITHUB_TOKEN'
                        )
                    ]) {
                        sh '''
                            set +x
                            set -eu

                            ZIP="artifact/R1-${BUILD_NUMBER}.zip"
                            API="https://api.github.com/repos/Lorcar95/oracle-cicd_demo"

                            test -f "$ZIP"

                            echo "Creating GitHub prerelease..."

                            HTTP_CODE=$(curl --silent --show-error \
                                --output github-release-response.json \
                                --write-out '%{http_code}' \
                                -X POST \
                                -H "Authorization: Bearer $GITHUB_TOKEN" \
                                -H "Accept: application/vnd.github+json" \
                                -H "X-GitHub-Api-Version: 2022-11-28" \
                                -H "Content-Type: application/json" \
                                --data-binary @github-release.json \
                                "$API/releases")

                            if [ "$HTTP_CODE" != "201" ]; then
                                echo "GitHub release creation failed. HTTP $HTTP_CODE"
                                exit 1
                            fi

                            UPLOAD_URL=$(sed -n \
                                's/.*"upload_url": *"\\([^"]*\\)".*/\\1/p' \
                                github-release-response.json | cut -d '{' -f 1)

                            if [ -z "$UPLOAD_URL" ]; then
                                echo "Could not extract GitHub upload URL."
                                exit 1
                            fi

                            echo "Uploading deployment ZIP..."

                            HTTP_CODE=$(curl --silent --show-error \
                                --output github-upload-response.json \
                                --write-out '%{http_code}' \
                                -X POST \
                                -H "Authorization: Bearer $GITHUB_TOKEN" \
                                -H "Accept: application/vnd.github+json" \
                                -H "X-GitHub-Api-Version: 2022-11-28" \
                                -H "Content-Type: application/zip" \
                                --data-binary @"$ZIP" \
                                "${UPLOAD_URL}?name=R1-${BUILD_NUMBER}.zip")

                            if [ "$HTTP_CODE" != "201" ]; then
                                echo "GitHub artifact upload failed. HTTP $HTTP_CODE"
                                exit 1
                            fi

                            echo "GitHub prerelease published successfully."
                        '''
                    }
                }
            }
        }
    }
}
