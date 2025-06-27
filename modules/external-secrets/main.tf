 

resource "time_sleep" "wait_60_seconds_for_external_secret_controller" {
  create_duration = "60s"
  depends_on = [helm_release.external_secrets]
}

# Creating Kubernetes SecretStore in the cluster so that Secrets can synchronise from AWS Secrets Manager
# Once Secrets are synchronised Pods can use the secrets within the cluster



resource "kubectl_manifest" "kubernetes-secret-store" {
    wait = true
    yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: "${var.k8s_cluster_name}-common-secret-store"
  namespace:  ${var.app_namespace}
spec:
  provider:
    aws:
      service: SecretsManager
      region: ${local.aws_region_name}
      auth:
        jwt:
          serviceAccountRef:
            name: ${local.service_account_name}
YAML

depends_on = [   
                helm_release.external_secrets , 
                kubernetes_service_account.this, 
                time_sleep.wait_60_seconds_for_external_secret_controller  
                ]
}

 

 
# We will now create our ExternalSecret resource, specifying the secret we want to access and referencing the previously created SecretStore object. 
# We will specify the existing AWS Secrets Manager secret name and keys.


resource "time_sleep" "wait_30_seconds_for_secret_store" {
  create_duration = "30s"
  depends_on = [kubectl_manifest.kubernetes-secret-store]
}
 
 
resource "kubectl_manifest" "kubernetes-external-secret" {
    wait = true
    yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: "${var.k8s_cluster_name}-external-secret"
  namespace:  ${var.app_namespace}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: "${var.k8s_cluster_name}-common-secret-store"
    kind: SecretStore
  target:
    name:  "application-credentials"
    creationPolicy: Owner
  data:
  - secretKey:  "application-username"
    remoteRef:
      key: "test/application/credentials" #AWS Secrets Manager secret name
      property:  "app-username" #AWS Secrets Manager secret key
  - secretKey: "application-password"
    remoteRef:
      key: "test/application/credentials" #AWS Secrets Manager secret name
      property: "app-password" #AWS Secrets Manager secret key
YAML

depends_on = [ kubectl_manifest.kubernetes-secret-store , time_sleep.wait_30_seconds_for_secret_store  ]

}



# https://github.com/hashicorp/terraform-provider-kubernetes-alpha/issues/199#issuecomment-832614387

/*
 
resource "kubernetes_manifest" "kubernetes-secret-store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "SecretStore"
      metadata = {
          name = "${var.k8s_cluster_name}-common-secret-store"
          namespace =  var.app_namespace
      }
      spec = {
          provider = {
            aws = {
              service = "SecretsManager"
              region = local.aws_region_name
              auth = {
                jwt = {
                  serviceAccountRef = {
                    name = local.service_account_name
                  }
                }
              }
            }
          }
      }
  }
}
 
 */

 

 /*
 
resource "kubernetes_manifest" "kubernetes-external-secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
        metadata = {
          name = "${var.k8s_cluster_name}-external-secret"
          namespace =  var.app_namespace
        }
        spec = {
          refreshInterval = "1h"
          secretStoreRef = {
            name = "${var.k8s_cluster_name}-common-secret-store"
            kind = "SecretStore"
          }
          target = {
            name = "application-credentials"
            creationPolicy = "Owner"
          }
          data = [{
              secretKey =  "application-username"
              remoteRef = {
                key = "test/application/credentials" #AWS Secrets Manager secret name
                property =  "app_username" #AWS Secrets Manager secret key
              }
              secretKey = "application-password"
              remoteRef = {
                key = "test/application/credentials" #AWS Secrets Manager secret name
                property = "app_password" #AWS Secrets Manager secret key
              }
          }]
        }
  }
}
 
 */