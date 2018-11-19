### @color[orange](Jenkinsfile) - What, why, where, how
(you too can write pipeline code!)

---

### TIL (Background info):

- Pipeline as code
- DevOps Jenkins
- JobDSL pipeline
- Jenkinsfile pipeline
- EVE-Jenkins-Pipeline (shared library)

---

### Pipeline as code

Defining the deployment pipeline through code as opposed to manually configuring things via a GUI

+++

### Benefits

@ul

- Reproducibility (tear down, redeploy)
- Automated
- Less manual effort = less human error

@ulend

+++

### Repos to pull down and clone

@ul

- uscis-jenkins
- eve-jenkins-pipeline
- uscis-pipeline-gem

@ulend

---

### USCIS-Jenkins

- Cookbooks and scripts to create Jenkins servers
- Used by ENR, Save, SVS, VDM

+++

### Gotcha:

This repo is sort of meta.

+++

#### The main script will create a @color[orange](__DevOps Jenkins__) server that hosts the pipeline jobs that create:

- Other Jenkins Servers such as (ENR Jenkins, PROD ENR Jenkins, Save Jenkins, etc.)
- Another instance of itself - why would you want this?

---

### What happens when you trigger a DevOps-Jenkins build?

+++

#### 1. create-jenkins-for-devops

- Note: `JENKINS_SEEDSET`
- Executes this command:

```sh
. rvm.env; bundle install; jobs/scripts/create-jenkins-instance.sh
```
+++

#### 2. jobs/scripts/create-jenkins-instance.sh

```sh
JENKINS_SEEDSET="${JENKINS_SEEDSET:-devops}"

aws cloudformation create-stack \
  --stack-name $cfn_stack_name \
  --template-body file:///tmp/jenkins-asg-cfn.json \
  --region $region \
  --capabilities="CAPABILITY_IAM" \
  --disable-rollback \
  --parameters \
    ...redacted...
    ParameterKey=jenkinsPrefix,ParameterValue="$jenkins_prefix" \
    ParameterKey=jenkinsKeyBucket,ParameterValue="$jenkins_key_bucket" \
    ParameterKey=JenkinsSeedset,ParameterValue="$JENKINS_SEEDSET" \
    ...redacted...
  --tags \
    Key=Server_Function,Value="Jenkins"
```

@[1, 13](Creates a jenkins cloudformation stack that knows our JenkinsSeedset parameter value)

+++

#### 3. cookbooks/jenkins-config/attributes/seeds.rb

```sh
node.default['jenkins-config']['seedsets'] = {
  'devops' => [
    { 'name' => 'jenkins',
      'repo' => 'git@git.uscis.dhs.gov:USCIS/uscis-jenkins.git',
      'file' => 'jobs/dsl/jobdsl.groovy',
      'command' => '. rvm.env;echo success' },
  ]
}
```

@[2](JENKINS_SEEDSET = 'devops')
@[3-6](Jenkins seedset that creates jobs)
@[5](Filepath of the script to execute)

+++

#### 4. jobs/dsl/jobdsl.groovy

```groovy
// Define list for create jenkins and misc jobs
def createJenkinsJobNames = ["svs", "vdm", "enr", "devops", "sharedtest", "save", "prod"] as String[]

// Create Standalone Jobs for Jenkins Instance Creations and other Misc jobs
createJenkinsJobNames.each { jobName ->
  job("create-jenkins-for-${jobName}") { jobContext ->
    JobSetup.create_jenkins_jobs(jobContext, "${jobName}")
  }
}
```

@[2](Array of all the different Jenkins we want to create)
@[5-9](Executes `create-jenkins-instance.sh` under the hood with dynamic JENKINS_SEEDSET)

+++

### META!

---
