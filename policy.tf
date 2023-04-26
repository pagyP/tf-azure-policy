
//assign policy to management group scope
resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  name                 = "allowed_locations"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  description          = "Allowed locations for resources"
  display_name         = "Allowed locations"
  enforce              = true //set to true to enforce policy.  For deny policies this means the action will be denied
  parameters           = <<PARAMS
    {
        "listOfAllowedLocations": {
        "value": [
            "eastus",
            "eastus2",
            "westus"
        ]
        }
    }
    
    PARAMS
}


//assign policy to subscription scope
# resource "azurerm_subscription_policy_assignment" "allowed_locations" {
#   name                 = "allowed_locations"
#   subscription_id      = var.subscription_name
#   policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
#   description          = "Allowed locations for resources"
#   display_name         = "Allowed locations"
#   enforce              = true //set to true to enforce policy.  For deny policies this means the action will be denied
#   parameters           = <<PARAMS
#     {
#         "listOfAllowedLocations": {
#         "value": [
#             "eastus",
#             "eastus2",
#             "westus"
#         ]
#         }
#     }
    
#     PARAMS
# }

# //assign policy to resource group scope
# resource "azurerm_resource_group_policy_assignment" "allowed_locations" {
#   name                 = "allowed_locations"
#   resource_group_name  = "/subscriptions/f8bf7adc-eeed-4320-b9e4-b30e582ef115/resourceGroups/rg-aks-wth"
#   policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
#   description          = "Allowed locations for resources"
#   display_name         = "Allowed locations"
#   enforce              = true //set to true to enforce policy.  For deny policies this means the action will be denied
#   parameters           = <<PARAMS
#     {
#         "listOfAllowedLocations": {
#         "value": [
#             "eastus",
#             "eastus2",
#             "westus"
#         ]
#         }
#     }
    
#     PARAMS
# }

//TAGS

//deny resource if tag is not present
resource "azurerm_management_group_policy_assignment" "envtagging" {
  name                 = "EnvironmentTag"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
  description          = "Enforce use of Environment tag name"
  display_name         = "Enforce use of Environment tag name"
  enforce              = true //set to true to enforce policy.  For deny policies this means the action will be denied
  parameters           = <<PARAMS
    {
        "tagName": {
        "value": "Environment"
        }
    }
    
    PARAMS
}

//require a tag on resource groups
resource "azurerm_management_group_policy_assignment" "rgenvtagging" {
  name                 = "ResourceGroupTag"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  description          = "Enforce use of Environment tag name on RGs"
  display_name         = "Enforce use of Environment tag name on RGs"
  enforce              = true //set to true to enforce policy.  For deny policies this means the action will be denied
  parameters           = <<PARAMS
    {
        "tagName": {
        "value": "Environment"
        }
    }
    
    PARAMS
}

resource "azurerm_management_group_policy_assignment" "mandatorytagandvalue" {
  name                 = "mandatorytagandvalue"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62"
  description          = "Enforce use of mandatory tag and value"
  display_name         = "Enforce use of mandatory tag and value"
  enforce              = true //set to true to enforce policy.  For deny policies this means the action will be denied
  parameters           = <<PARAMS
    {
        "tagName": {
        "value": "Environment"
        },
        "tagValue": {
            "value": "Dev"
            }
    }
    
    PARAMS
}

//audit policy initiative
resource "azurerm_management_group_policy_assignment" "networkaccessauditpol" {
    name = "networkaccessauditpol"
    management_group_id = var.management_group_id
    policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/f1535064-3294-48fa-94e2-6e83095a5c08"
    description = "Audit network access"
    display_name = "Audit network access"
    
}


//custom policy defintion
resource "azurerm_policy_definition" "sqlvulnassessment" {
    name         = "sqlvulnassessment"
    policy_type  = "Custom"
    mode         = "All"
    display_name = "SQL Vulnerability Assessment-Custom-TF"
    description  = "Enables SQL Vulnerability Assessment on all SQL Servers in the subscription"
    management_group_id = var.management_group_id

    metadata = <<METADATA
    {
    "category": "General"
    }

METADATA

    policy_rule = <<POLICY_RULE
    {
        "if": {
               "field": "type",
               "equals": "Microsoft.Sql/servers"
            },
            "then": {
               "effect": "deployIfNotExists",
               "details": {
                  "type": "Microsoft.Sql/servers/sqlVulnerabilityAssessments",
                  "name": "Default",
                  "existenceCondition": {
                     "field": "Microsoft.Sql/servers/sqlVulnerabilityAssessments/state",
                     "equals": "Enabled"
                  },
                  "roleDefinitionIds": [
                    "/providers/Microsoft.Authorization/roleDefinitions/056cd41c-7e88-42e1-933e-88ba6a50c9c3",
                    "/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa"
                  ],
                  "deployment": {
                     "properties": {
                        "mode": "incremental",
                        "template": {
                           "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
                           "contentVersion": "1.0.0.0",
                           "parameters": {
                              "serverName": {
                                 "type": "string"
                              }
                           },
                           "variables": {},
                           "resources": [
                              {
                                 "name": "[concat(parameters('serverName'), '/Default')]",
                                 "type": "Microsoft.Sql/servers/sqlVulnerabilityAssessments",
                                 "apiVersion": "2022-08-01-preview",
                                 "properties": {
                                    "state": "Enabled"
                                 }
                              }
                           ]
                        },
                        "parameters": {
                           "serverName": {
                              "value": "[field('name')]"
                           }
                        }
                     }
                  }
               }
            }
         }
POLICY_RULE
}

resource "azurerm_management_group_policy_assignment" "sqlvulnassessment" {
    name = "sqlvulnassessment"
    management_group_id = var.management_group_id
    policy_definition_id = azurerm_policy_definition.sqlvulnassessment.id
    description = "Enables SQL Vulnerability Assessment on all SQL Servers in the subscription"
    display_name = "SQL Vulnerability Assessment-Custom-TF"
    location = "uksouth"
    identity {
        type = "SystemAssigned"
    }
    
}

resource "azurerm_role_assignment" "sqlvulnassessment" {
    scope = var.management_group_id
    role_definition_name = "Monitoring Contributor"
    principal_id = azurerm_management_group_policy_assignment.sqlvulnassessment.identity[0].principal_id
}

resource "azurerm_role_assignment" "sqlvulnassessment1" {
    scope = var.management_group_id
    role_definition_name = "SQL Security Manager"
    principal_id = azurerm_management_group_policy_assignment.sqlvulnassessment.identity[0].principal_id
}

//deploy if not exists

resource "azurerm_management_group_policy_assignment" "deployifnotexistsiaasmalwareextension" {
    name = "deployifnotexists"
    management_group_id = var.management_group_id
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2835b622-407b-4114-9198-6f7064cbe0dc"
    description = "Deploy if not exists - IaaS Windows Anti Malware Extension"
    display_name = "Deploy if not exists - IaaS Windows Anti Malware Extension"
    location = "uksouth"
    identity {
        type = "SystemAssigned"
    }
    
}

resource "azurerm_role_assignment" "windowsiaasmalwareextension" {
    //scope = azurerm_management_group_policy_assignment.deployifnotexists.id
    scope = var.management_group_id
    role_definition_name = "Virtual Machine Contributor"
    principal_id = azurerm_management_group_policy_assignment.deployifnotexistsiaasmalwareextension.identity.0.principal_id
}



resource "azurerm_management_group_policy_assignment" "inherittagfromsub" {
    name = "inherittagfromsubs"
    management_group_id = var.management_group_id
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/40df99da-1232-49b1-a39a-6da8d878f469"
    description = "Inherit SubType Tag and value from subscription"
    display_name = "Inherit SubType Tag and value from subscription"
    location = "uksouth"
    parameters           = <<PARAMS
    {
        "tagName": {
        "value": "SubType"
        }
    }
    PARAMS
    identity {
        type = "SystemAssigned"
    }
    
}

resource "azurerm_role_assignment" "inherittagfromsub" {
    //scope = azurerm_management_group_policy_assignment.deployifnotexists.id
    scope = var.management_group_id
    role_definition_name = "Contributor"
    principal_id = azurerm_management_group_policy_assignment.inherittagfromsub.identity.0.principal_id
}

//TODO: Add append

resource "azurerm_management_group_policy_assignment" "appendtagtorg" {
    name = "appendtorg"
    management_group_id = var.management_group_id
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/49c88fc8-6fd1-46fd-a676-f12d1d3a4c71"
    description = "Append tag to RG"
    display_name = "Append tag to rg"
    location = "uksouth"
    parameters           = <<PARAMS
    {
        "tagName": {
        "value": "AppendTag"
        },
        "tagValue": {
         "value": "AppendValue"
        }
    }
    PARAMS
   #  identity {
   #      type = "SystemAssigned"
   #  }
    
}