pipeline {
    agent any

    environment {
        DOCKERHUB_USER   = 'shamyugtha'
        BACKEND_IMAGE    = "${DOCKERHUB_USER}/shopnest-backend"
        FRONTEND_IMAGE   = "${DOCKERHUB_USER}/shopnest-frontend"
        VERSION          = "1.0.${BUILD_NUMBER}"
    }

    options {
        // Best practice: clean up old builds, don't accumulate forever
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Best practice: prevent concurrent builds stepping on each other's Docker resources
        disableConcurrentBuilds()
        // Safety net: kill the build if it hangs beyond 30 minutes
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {

        stage('Checkout') {
            steps {
                // Groovy as glue — checkout scm is a single built-in step, not custom logic
                checkout scm
                echo "Branch: ${env.BRANCH_NAME} | Build: ${env.BUILD_NUMBER}"
            }
        }

        stage('Build') {
            steps {
                // Best practice: combine related shell commands into one sh block
                // BUILD_DATE computed in shell, not Groovy — avoids serialization issues
                sh '''
                    BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

                    docker build \
                        --build-arg BUILD_DATE=$BUILD_DATE \
                        --build-arg VERSION=$VERSION \
                        -t $BACKEND_IMAGE:$VERSION \
                        -t $BACKEND_IMAGE:latest \
                        ./backend

                    docker build \
                        --build-arg BUILD_DATE=$BUILD_DATE \
                        --build-arg VERSION=$VERSION \
                        -t $FRONTEND_IMAGE:$VERSION \
                        -t $FRONTEND_IMAGE:latest \
                        ./frontend
                '''
            }
        }

        stage('Test') {
            steps {
                // withCredentials injects .env at runtime — never stored in repo or image
                withCredentials([file(credentialsId: 'shopnest-backend-env', variable: 'ENV_FILE')]) {
                    // Best practice: one sh block does all test work — start, wait, verify, stop
                    sh '''
                        # Isolated per-build network — no collision between concurrent builds
                        docker network create shopnest-test-$BUILD_NUMBER

                        # Start backend
                        docker run -d \
                            --name backend-test-$BUILD_NUMBER \
                            --network shopnest-test-$BUILD_NUMBER \
                            --env-file $ENV_FILE \
                            $BACKEND_IMAGE:$VERSION

                        # Poll healthcheck — shell loop, not Groovy logic
                        echo "Waiting for backend to be healthy..."
                        ATTEMPTS=0
                        until [ "$(docker inspect --format='{{.State.Health.Status}}' backend-test-$BUILD_NUMBER)" = "healthy" ]; do
                            ATTEMPTS=$((ATTEMPTS + 1))
                            if [ $ATTEMPTS -ge 12 ]; then
                                echo "Backend failed to become healthy after 2 minutes"
                                exit 1
                            fi
                            echo "Attempt $ATTEMPTS/12 — waiting..."
                            sleep 10
                        done
                        echo "Backend is healthy"

                        # Start frontend
                        docker run -d \
                            --name frontend-test-$BUILD_NUMBER \
                            --network shopnest-test-$BUILD_NUMBER \
                            $FRONTEND_IMAGE:$VERSION

                        # Give frontend 10 seconds to start
                        sleep 10

                        # Verify both health endpoints respond
                        docker exec backend-test-$BUILD_NUMBER \
                            node -e "require('http').get('http://localhost:5000/health', r => { process.exit(r.statusCode === 200 ? 0 : 1) })"

                        docker exec frontend-test-$BUILD_NUMBER \
                            wget -q --spider http://localhost:8080/health
                    '''
                }
            }
            post {
                // Best practice: cleanup always runs — even if test stage fails
                // Prevents orphaned containers/networks accumulating on Jenkins host
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
            // Only push from main branch — feature branches build and test but never push
            when {
                branch 'main'
            }
            steps {
                // withCredentials — token never appears in logs, Jenkins masks it
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    // Best practice: one sh block — login, push both images, logout
                    // docker logout ensures no credentials cached on Jenkins host after push
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
                // Remove images from Jenkins host — Jenkins is not a registry
                // || true prevents failure if image was already removed
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
            echo "SUCCESS — shamyugtha/shopnest-backend:${VERSION} and shamyugtha/shopnest-frontend:${VERSION} pushed to Docker Hub"
        }
        failure {
            echo "FAILED — check the stage logs above to identify which stage broke"
        }
        always {
            // Best practice from doc: clean workspace after every build
            // Prevents workspace disk bloat over hundreds of builds
            cleanWs()
        }
    }
}