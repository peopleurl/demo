pipeline {
  agent {
    kubernetes {
      cloud 'kubernetes'
      slaveConnectTimeout 1000
      yaml '''
apiVersion: v1
kind: Pod
spec:
  hostAliases:
  - hostnames:
    - harbor.deployers.cn
    - jenkins.deployers.cn
    ip: 192.168.1.12
  containers:
    - args: [\'$(JENKINS_SECRET)\', \'$(JENKINS_NAME)\']
      image: \'harbor.deployers.cn/library/inbound-agent:v1.0\'
      name: jnlp
      imagePullPolicy: IfNotPresent
      volumeMounts:
        - mountPath: "/etc/localtime"
          name: "volume-2"
          readOnly: false     
    - command:
        - "cat"
      env:
        - name: "LANGUAGE"
          value: "en_US:en"
        - name: "LC_ALL"
          value: "en_US.UTF-8"
        - name: "LANG"
          value: "en_US.UTF-8"
      image: "harbor.deployers.cn/library/maven:3.9.9-key"
      imagePullPolicy: "IfNotPresent"
      name: "build"
      tty: true
      volumeMounts:
        - mountPath: "/etc/localtime"
          name: "volume-2"
          readOnly: false
        - mountPath: "/root/.m2/"
          name: "volume-maven-repo"
          readOnly: false
    - command:
        - "bash"
      env:
        - name: "LANGUAGE"
          value: "en_US:en"
        - name: "LC_ALL"
          value: "en_US.UTF-8"
        - name: "LANG"
          value: "en_US.UTF-8"
      image: "harbor.deployers.cn/library/kubectl:1.26.14"
      imagePullPolicy: "IfNotPresent"
      name: "kubectl"
      tty: true
      volumeMounts:
        - mountPath: "/etc/localtime"
          name: "volume-2"
          readOnly: false
        - mountPath: "/root/.kube/"
          name: "volume-kubeconfig"
          readOnly: false
    - command:
        - sh
        - /usr/local/bin/dockerd-entrypoint.sh
      env:
        - name: "LANGUAGE"
          value: "en_US:en"
        - name: "LC_ALL"
          value: "en_US.UTF-8"
        - name: "LANG"
          value: "en_US.UTF-8"
      image: "harbor.deployers.cn/library/docker:26.1.4"
      imagePullPolicy: "IfNotPresent"
      name: "docker"
      tty: true
      securityContext:
        privileged: true
      volumeMounts:
        - mountPath: "/etc/localtime"
          name: "volume-2"
          readOnly: false
        - mountPath: "/var/lib/docker"
          name: "docker-storage"
          readOnly: false  
  imagePullSecrets:
  - name: harbor-login-auth    
  restartPolicy: "Always"
  volumes:
    - hostPath:
        path: "/etc/localtime"
      name: "volume-2"
    - name: "volume-maven-repo"
      persistentVolumeClaim:
           claimName: "jenkins-maven"
    - name: "volume-kubeconfig"
      secret:
        secretName: "multi-kube-config"
    - name: "docker-storage"
      emptyDir: {}
'''
    }

  }

    triggers {
        pollSCM('H/1 * * * *') // 每 5 分钟轮询 SCM
    }

  stages {
    stage('pulling Code') {
      parallel {

        stage('pulling Code by trigger') {
          steps {
            script {
                     echo "Pulling code from GitLab branch: ${env.gitlabBranch}"
                     git(url: "git@github.com:peopleurl/demo.git", branch: "main", credentialsId: '0d6fc179-b32e-4e3c-a909-6c1c5a3e4bf5')
            }
          }
        }

      }
    }

    stage('initConfiguration') {
      steps {
        script {
          CommitID = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()
          CommitMessage = sh(returnStdout: true, script: "git log -1 --pretty=format:'%h : %an  %s'").trim()
          def curDate = sh(script: "date '+%Y%m%d-%H%M%S'", returnStdout: true).trim()
          TAG = curDate[0..14] + "-" + CommitID + "-" + "main"
        }

      }
    }

    stage('Building') {
      parallel {
        stage('Building') {
          steps {
            container(name: 'build') {
              sh """

                          echo "Building Project..."
                          mvn clean package
                 """
            }

          }
        }

        stage('Scan Code') {
          steps {
            sh 'echo "Scan Code"'
          }
        }

      }
    }

    stage('Build image') {
      steps {
        withCredentials(bindings: [usernamePassword(credentialsId: 'c4e71801-96ef-4ed6-bb11-69e302a053de', passwordVariable: 'Password', usernameVariable: 'Username')]) {
          container(name: 'docker') {
            sh """
                      docker login -u ${Username} -p ${Password} harbor.deployers.cn
                      docker build -t harbor.deployers.cn/demo/demo01:${TAG} .
                      docker push harbor.deployers.cn/demo/demo01:${TAG}
                      """
          }

        }

      }
    }

    stage('Deploy') {
      when {
        expression {
          false != "false"
        }

      }
      steps {
        container(name: 'kubectl') {
          sh """

              kubectl set image deployment -l app=java-demo java-demo=harbor.deployers.cn/demo/demo01:${TAG} -n java-demo
             """
        }

      }
    }

  }
  environment {
    CommitID = ''
    CommitMessage = ''
    TAG = ''
  }
}
