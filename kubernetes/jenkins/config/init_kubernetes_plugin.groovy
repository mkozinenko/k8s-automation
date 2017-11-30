import org.csanchez.jenkins.plugins.kubernetes.*
import jenkins.model.*

def j = Jenkins.getInstance()

def k = new KubernetesCloud(
        'jenkins',
        null,
        'https://kubernetes/',
        'jenkins',
        'http://jenkins:8080/',
        '10', 15, 15, 5
)

k.setSkipTlsVerify(true)
j.clouds.replace(k)
j.save()