
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

//audit policy
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

//TODO: Add append, modify and deployIfNotExists examples