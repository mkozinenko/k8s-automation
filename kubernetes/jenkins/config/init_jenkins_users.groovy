package dockerified.config
// from https://gist.github.com/jnbnyc/c6213d3d12c8f848a385
import jenkins.*
import hudson.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import hudson.plugins.sshslaves.*;
import hudson.model.*
import jenkins.model.*
import hudson.security.*

global_domain = Domain.global()
credentials_store =
        Jenkins.instance.getExtensionList(
                'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
        )[0].getStore()

credentials = new BasicSSHUserPrivateKey(CredentialsScope.GLOBAL,null,"root",new BasicSSHUserPrivateKey.UsersPrivateKeySource(),"","")

credentials_store.addCredentials(global_domain, credentials)

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
def adminUsername = System.getenv('JENKINS_ADMIN_USERNAME') ?: 'admin'
def adminPassword = System.getenv('JENKINS_ADMIN_PASSWORD') ?: 'admin'
hudsonRealm.createAccount(adminUsername, adminPassword)
//hudsonRealm.createAccount("charles", "charles")

def instance = Jenkins.getInstance()
instance.setSecurityRealm(hudsonRealm)
instance.save()


def strategy = new GlobalMatrixAuthorizationStrategy()

// Setting Admin Permissions
strategy.add(Jenkins.ADMINISTER, "admin")


instance.setAuthorizationStrategy(strategy)
instance.save()