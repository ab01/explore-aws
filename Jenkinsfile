node {
   // Mark the code checkout 'stage'....
   stage 'Checkout'

   git branch: 'develop', credentialsId: 'jenkins_cd', url: 'https://github.com/ab01/explore-aws.git'   

   // Get the maven tool.
   // ** NOTE: This 'M3' maven tool must be configured
   // **       in the global configuration.           
   // ** def mvnHome = tool 'M3'

   // Mark the code build 'stage'....
   stage 'Build'
   // Run the maven build
     sh "sudo /var/lib/jenkins/packer build --var-file variables.json packer-nginx-dockerhub.json"
   //sh "${mvnHome}/bin/mvn -Dmaven.test.failure.ignore clean package"
   //step([$class: 'JUnitResultArchiver', testResults: '**/target/surefire-reports/TEST-*.xml'])
     echo 'run the build'
   // Mark the code test: functional 'stage'....
   stage 'test: functional'
      echo 'run the test'
    // Mark the code deploy: dev 'stage'....
   stage 'deploy: dev'
      echo 'deploy on dev docker'
   // Mark the code approval 'stage'....
   stage 'approval'
      echo 'approval completed'
   
   // Mark the code deploy: prod 'stage'....
   stage 'deploy: prod'
      echo 'deploy on prd'
}
