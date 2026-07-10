pipeline {
    agent any

    environment {
        DOCKERHUB_USER  = 'shamyugtha'
        BACKEND_IMAGE   = "${DOCKERHUB_USER}/shopnest-backend"
        FRONTEND_IMAGE  = "${DOCKERHUB_USER}/shopnest-frontend"
        VERSION         = "1.0.${BUILD_NUMBER}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo "Build: ${env.BUILD_NUMBER}"
            }
        }

        stage('Build') {
            steps {
                sh '''
                    BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                    docker build --build-arg BUILD_DATE=$BUILD_DATE --build-arg VERSION=$VERSION -t $BACKEND_IMAGE:$VERSION -t $BACKEND_IMAGE:latest ./backend
                    docker build --build-arg BUILD_DATE=$BUILD_DATE --build-arg VERSION=$VERSION -t $FRONTEND_IMAGE:$VERSION -t $FRONTEND_IMAGE:latest ./frontend
                '''
            }
        }

        stage('Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'shopnest-doc',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push $BACKEND_IMAGE:$VERSION
                        docker push $BACKEND_IMAGE:latest
                        docker push $FRONTEND_IMAGE:$VERSION
                        docker push $FRONTEND_IMAGE:latest
                        docker logout
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                    docker rmi $BACKEND_IMAGE:$VERSION || true
                    docker rmi $BACKEND_IMAGE:latest || true
                    docker rmi $FRONTEND_IMAGE:$VERSION || true
                    docker rmi $FRONTEND_IMAGE:latest || true
                '''
            }
        }
    }

    post {
        success {
            echo "SUCCESS — images pushed to Docker Hub"
        }
        failure {
            echo "FAILED — check logs above"
        }
        always {
            cleanWs()
        }
    }
}