### Premise

You need to build and deploy helm charts similar to container images.  By this I mean we want to be able to version the release, test it, deploy it to a central location, and consume it on various kubernetes clusters.

Helm charts are generally useful for deploying an application, but maintenance and testing on the charts creeps up.  For example an older nginx ingress chart may need to be updated to comply with more current RBAC implementations.  Similarly, a person might forget that "networking/v1" for implementing network policies is only available in 1.7 and not realize that their updated chart no longer works with an older kubernetes environment.

I wanted to describe what I've done to solve some of this, comment about the rough edges that I've found, and see if anyone in the community has done a similar thing or would like to work on a better way to do it.

### What I Did

**Repository per Chart**

While github.com/kubernetes/charts has some great charts, it does not have **all the charts**.  And regardless, even if it did, you might need to make changes for your needs.  We began with a single a repository of helm charts, but it was not great for having older versions of the charts or even easily seeing in source control when releases of individual charts were made.  Because of that I opted to move to a repository per chart model.  This way tagging, branching and forking of this chart would be a bit more bite sized and easier to manage.  

You can see an example of it by going to https://github.com/samsung-cnct/chart-mongodb-replicaset

**Use quay.io to store charts**

I'm not nearly as awesome as others, so the likelihood of getting all of my charts included into kubernetes/charts is very low.  I also figured it did not make sense to maintain my own website that had my charts for a couple of reasons.  One, that was maintenance I did not want to have to maintain.  Two, I would like to share my charts with the community.  Docker hub has been great for sharing container images, github is great for sharing source code, and while I should be allowed to run my own server to store helm charts, I'd prefer to be able to discoverable by others without using Google.

Because of that, I decided to publish my charts to quay.io using the [helm appregistry plugin](https://github.com/app-registry/appr-helm-plugin).  It works and solves my problems of having auditing, versioning, and I'm not maintaining it.

You can see an example application repository by looking at https://quay.io/application/samsung_cnct/mongodb-replicaset

https://github.com/samsung-cnct/template-chart/blob/master/docs/quay.md

**Use Jenkins to build and test charts**

Once I had a repository for my chart and a place to store it once it was tested and built, I needed something to make the magic happened.  I turned to Jenkins (running in Kubernetes I might add :) ) Multi-branch Pipelines.

The logic right now is relatively simple:  When you're ready to do a release tag it in github and push it up.  Take the tag, insert its value into Chart.yaml for the version, do a test (currently just linting, but will do a lot more later), and then, assuming things pass, publish it up to quay.

Jenkins was chosen in part because it is free (like everything else chosen above this), but I'm sure other CI/CD systems could be used.

You can see this by going to https://common-jenkins.kubeme.io/job/chart-mongodb-replicaset/

Rough Edges

Build / Jenkins settings
Helm does have a concept of tests - https://github.com/kubernetes/helm/blob/master/docs/chart_tests.md - but it probably needs a bit of help to enhance it from "Test a specific installation" to "Test a matrix of installations installed on a series of kubernetes environments"  This might have been out of scope for the original tests, or I'm just missing it

Furthermore, I'm not sure where artifacts like "Jenkinsfile" belongs within helm charts.  Currently (and for reasons covered in the next section) I put the chart in a subfolder and create a folder called 'build' that had build information in it - but not everyone will want to use Jenkins and it might be too specific (targeting different kubernetes installations, etc.)

Hard to fork and contribute back
Don't get me wrong - I like that there is a kubernetes/chart repo.  But if you move to a "one repo per chart" model, it is hard to simply fork an existing chart in kubernetes/chart, improve it and submit the changes back to the author.  This may seem frivolous, but I think the easier it is for someone to make an improvement to an existing chart the better it is for the entire community.

Has anyone done something similar or better?

I doubt I'm the only one that has wanted versioned helm chart releases or that wanted to have a build server build them.  But in my limited ability to effectively google, I have not seen a similar set up (centralized helm chart repository, build server, etc.) so that's why I'm posting here.  If someone else has a similar set of needs and has solved it either radically different or similar, perhaps we can work together to help others who will inevitably run into a similar situation.

An additional link that could be helpful
https://github.com/samsung-cnct/template-chart/tree/master/docs - instructions I've given on how to configure a new chart to do what I've been doing.

Thanks

Mike