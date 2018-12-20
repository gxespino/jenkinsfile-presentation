### @color[orange](USCIS-Jenkins) - What, why, where, how
(you too can write pipeline code!)

---

### TIL:

- Where do our pipeline jobs originate?
- What happens under the hood when you trigger a pipeline job?
  - Connect the dots and pull back the curtain on our pipelines

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

### Steps

1. DevOps Jenkins
2. Pipeline USCIS Jenkins - Create Instance
3. JenkinsfileInstance
   3a. create_instance.rake - jenkins_prefix
4. Cloudformation - provisioning/jenkins_instance.yml
   4a. JenkinsSeedset -> export SEEDSET -> jenkins_config[seedset]
   4b. runlist -> recipe[jenkins-config::jobs]
5. jenkins_config/recipes/jobs.rb
6. jenkins_config/attributes/seeds.rb

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

#### 1. uscis-jenkins-create-instance

- Note: `jenkins_prefix`
- Executes this script: `JenkinsfileInstance`

+++

#### 2. uscis-jenkins/JenkinsfileInstance


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
