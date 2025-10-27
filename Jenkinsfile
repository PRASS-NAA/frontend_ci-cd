pipeline {
    agent any

    environment {
        // --- Securely load credentials into environment variables ---
        // We do NOT load the password here, as it's insecure.
        EC2_PUBLIC_IP       = credentials('ec2-public-ip')
        DOCKER_HUB_USERNAME = credentials('docker-username')
        
        // --- Define non-secret configuration variables ---
        EC2_SSH_USER        = 'ec2-user' // Or 'ubuntu' if you use an Ubuntu AMI
        CONTAINER_NAME      = 'grant-canyon-fe' // The name for your running container
        DOCKER_IMAGE_NAME   = 'grant-canyon-fe' // The name of your image on Docker Hub
    }

    stages {
        stage('1. Get Code') {
            steps {
                echo "Pulling code from github repo"
                git "https://github.com/PRASS-NAA/frontend_ci-cd.git"
            }
        }

        stage('2. Build Frontend Image') {
            steps {
                echo "Creating frontend image"
                // Build and tag the image using our variables
                sh "docker build -t ${DOCKER_HUB_USERNAME}/${DOCKER_IMAGE_NAME}:latest ."
            }
        }

        stage('3. Login and Push to Docker Hub') {
            steps {
                echo "Logging in and pushing image from Jenkins..."
                // Use the 'Username with password' credential to log in and push
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    
                    // Log in on the Jenkins machine
                    sh "echo ${PASS} | docker login -u ${USER} --password-stdin"
                    
                    // Push from the Jenkins machine
                    sh "docker push ${DOCKER_HUB_USERNAME}/${DOCKER_IMAGE_NAME}:latest"
                }
            }
        }

        stage('4. Login to Docker on EC2') {
            steps {
                echo "Connecting to EC2 to log in to Docker Hub..."
                
                // 1. Get the 'docker-password' secret text credential
                withCredentials([string(credentialsId: 'docker-password', variable: 'DOCKER_PASS')]) {
                    
                    // 2. Get the 'ec2-ssh-key' to connect to the server
                    sshagent(credentials: ['ec2-ssh-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ${EC2_SSH_USER}@${EC2_PUBLIC_IP} '
                            
                            echo "--- Logging into Docker Hub on EC2 ---"
                            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_HUB_USERNAME}" --password-stdin
                            
                            '
                        """
                    }
                }
            }
        }

        stage('5. Pull Image on EC2') {
            steps {
                echo "Connecting to EC2 to pull image"
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_SSH_USER}@${EC2_PUBLIC_IP} '
                        
                        echo "--- Pulling new image ---"
                        docker pull ${DOCKER_HUB_USERNAME}/${DOCKER_IMAGE_NAME}:latest
                        
                        '
                    """
                }
            }
        }

        stage('6. Stop and Remove Old Container') {
            steps {
                echo "Stopping and removing old containers"
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_SSH_USER}@${EC2_PUBLIC_IP} '
                        
                        echo "--- Stopping and removing old container ---"
                        docker stop ${CONTAINER_NAME} || true
                        docker rm ${CONTAINER_NAME} || true

                        '
                    """
                }
            }
        }

        stage('7. Deploy New Container') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_SSH_USER}@${EC2_PUBLIC_IP} '

                        echo "--- Running new container ---"
                        docker run -d --name ${CONTAINER_NAME} -p 80:80 ${DOCKER_HUB_USERNAME}/${DOCKER_IMAGE_NAME}:latest
                        echo "--- Deployment complete! ---"
                        
                        '
                    """
                }
            }
        }
    }
}