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

        stage('Install Dependencies') {
    steps {
        sh '''
            npm ci
            cd backend && npm ci
            cd ../frontend && npm ci
        '''
    }
}

stage('SonarQube Analysis') {
    environment {
        SCANNER_HOME = tool 'SonarScanner'
    }
    steps {
        withSonarQubeEnv('SonarQube') {
            sh '''
                $SCANNER_HOME/bin/sonar-scanner
            '''
        }
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

        stage('Scan') {
            steps {
                sh '''
                    echo "=== Scanning backend image ==="
                    trivy image \
                        --exit-code 1 \
                        --severity CRITICAL \
                        --no-progress \
                        --timeout 5m \
                        $BACKEND_IMAGE:$VERSION

                    echo "=== Scanning frontend image ==="
                    trivy image \
                        --exit-code 1 \
                        --severity CRITICAL \
                        --no-progress \
                        --timeout 5m \
                        $FRONTEND_IMAGE:$VERSION
                '''
            }
        }

        stage('Test') {
    steps {
        withCredentials([file(credentialsId: 'shopnest-backend-env', variable: 'ENV_FILE')]) {
            sh '''
                docker network create shopnest-test-$BUILD_NUMBER

                docker run -d \
                    --name backend-test-$BUILD_NUMBER \
                    --network shopnest-test-$BUILD_NUMBER \
                    --env-file $ENV_FILE \
                    $BACKEND_IMAGE:$VERSION

                echo "Waiting for backend to be healthy..."
                ATTEMPTS=0
                until [ "$(docker inspect --format='{{.State.Health.Status}}' backend-test-$BUILD_NUMBER)" = "healthy" ]; do
                    ATTEMPTS=$((ATTEMPTS + 1))
                    if [ $ATTEMPTS -ge 12 ]; then
                        echo "Backend failed to become healthy"
                        docker logs backend-test-$BUILD_NUMBER
                        exit 1
                    fi
                    echo "Attempt $ATTEMPTS/12 — waiting..."
                    sleep 10
                done
                echo "Backend is healthy"

                docker run -d \
                    --name frontend-test-$BUILD_NUMBER \
                    --network shopnest-test-$BUILD_NUMBER \
                    $FRONTEND_IMAGE:$VERSION

                echo "Waiting for frontend to be healthy..."
                ATTEMPTS=0
                until [ "$(docker inspect --format='{{.State.Health.Status}}' frontend-test-$BUILD_NUMBER)" = "healthy" ]; do
                    ATTEMPTS=$((ATTEMPTS + 1))
                    if [ $ATTEMPTS -ge 12 ]; then
                        echo "Frontend failed to become healthy"
                        docker logs frontend-test-$BUILD_NUMBER
                        exit 1
                    fi
                    echo "Attempt $ATTEMPTS/12 — waiting..."
                    sleep 10
                done
                echo "Frontend is healthy"

                docker exec backend-test-$BUILD_NUMBER \
                    node -e "require('http').get('http://localhost:5000/health', r => { process.exit(r.statusCode === 200 ? 0 : 1) })"

                echo "All health checks passed"
            '''
        }
    }
    post {
        always {
            sh '''
                docker stop backend-test-$BUILD_NUMBER frontend-test-$BUILD_NUMBER || true
                docker rm backend-test-$BUILD_NUMBER frontend-test-$BUILD_NUMBER || true
                docker network rm shopnest-test-$BUILD_NUMBER || true
            '''
        }
    }
}



        stage('Push') {
            when {
        expression {
            return sh(
                script: 'git branch --show-current',
                returnStdout: true
            ).trim() == 'main'
        }
    }
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
    echo "Pipeline completed successfully."
}
        failure {
            echo "FAILED — check logs above"
        }
        always {
            cleanWs()
        }
    }
}