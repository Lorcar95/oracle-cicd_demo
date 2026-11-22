
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-read-token',
                    url: 'https://github.com/Lorcar95/oracle-cicd_demo.git'
            }
        }

        stage('Verify Source') {
            steps {
                sh '''
                    echo "Checking Oracle SQLcl Project..."
                    git log -1 --oneline
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
