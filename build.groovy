#!groovy

deployment = """
apiVersion: v1
kind: Service
metadata:
  name: springboot-demo
  labels:
    app: springboot-demo
spec:
  ports:
    - port: 80
      targetPort: 8080
      name: http
  selector:
    app: springboot-demo
    tier: backend
  type: NodePort

---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: springboot-demo
  labels:
    app: springboot-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: springboot-demo
      tier: backend
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: springboot-demo
        tier: backend
    spec:
      containers:
      - image: registry:5000/springboot-demo:latest
        imagePullPolicy: "Always"
        name: springboot-demo
        ports:
        - containerPort: 8080
          name: springboot-demo
"""

dockerfile = """
FROM mkozinenko/jdk8:152

ARG ARTIFACT_FILENAME

EXPOSE 8080

WORKDIR /home/app

COPY helloworld-springboot-0.0.1-SNAPSHOT.jar .

USER app

CMD java -jar *.jar
"""


podTemplate(
        label: 'slave',
        cloud: 'jenkins',
        name: 'jenkins-slave',
        namespace: 'default',
        containers: [
                containerTemplate(
                        name: 'jenkins-slave-mvn',
                        image: 'mkozinenko/jenkins-slave-mvn',
                        ttyEnabled: true,
                        privileged: false,
                        alwaysPullImage: false,
                        workingDir: '/home/jenkins',
                        command: 'cat'
                ),
                containerTemplate(
                name: 'dind',
                image: 'mkozinenko/docker-dind',
                ttyEnabled: true,
                privileged: true,
                envVars: [
                  containerEnvVar(key: 'DOCKER_DRIVER', value: 'overlay'),
                ]
                ),
                containerTemplate(
                        name: 'jenkins-slave-docker',
                        image: 'mkozinenko/jenkins-slave-docker',
                        ttyEnabled: true,
                        alwaysPullImage: true,
                        envVars: [
                          containerEnvVar(key: 'DOCKER_HOST', value: 'tcp://localhost:2375'),
                        ],
                        workingDir: '/home/jenkins',
                        command: 'cat'
                ),
                containerTemplate(
                        name: 'jenkins-slave-kubectl',
                        image: 'mkozinenko/jenkins-slave-kubectl',
                        ttyEnabled: true,
                        privileged: false,
                        alwaysPullImage: false,
                        workingDir: '/home/jenkins',
                        command: 'cat'
                )

        ]
) {
    node('slave') {
        currentBuild.result = "SUCCESS"
        try {
            timestamps {
                stage("Test and build jar") {
                    git url: 'https://github.com/GoogleCloudPlatform/getting-started-java.git'
                    container('jenkins-slave-mvn') {
                        echo "Testing project ..."
                        sh "cd helloworld-springboot && mvn clean test && mvn clean package"
                        echo "Building jar ..."
                        sh "mvn clean package"
                        archiveArtifacts artifacts: 'helloworld-springboot/target/*.jar', onlyIfSuccessful: true
                    }
                }
                stage("Build and push springboot webapp image") {
                    container('jenkins-slave-docker') {
                        echo "Building and pushing springboot-demo webapp image ..."
                        sh "echo \"${dockerfile}\" > ./Dockerfile"
                        sh "cp ${WORKSPACE}/helloworld-springboot/target/helloworld-springboot-0.0.1-SNAPSHOT.jar ."
                        sh "docker build -t registry:5000/springboot-demo:${env.BUILD_NUMBER} ."
                        sh "docker push registry:5000/springboot-demo:${env.BUILD_NUMBER}"
                        sh "docker rmi -f `docker images -q` | true"
                    }
                }
                stage("Deploy webapp") {
                    container('jenkins-slave-kubectl') {
                        def NAME = "springboot-demo"
                        deployment = deployment.replaceAll('springboot-demo:latest', "springboot-demo:${env.BUILD_NUMBER}")
                        sh "echo ${deployment} | kubectl apply -f -"
                        sleep time: 120, unit: 'SECONDS'

                    }
                }

            }
        }
        catch (err) {

            currentBuild.result = "FAILURE"

            throw err
        }
    }
}