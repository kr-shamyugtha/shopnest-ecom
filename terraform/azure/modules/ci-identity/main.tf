data "azurerm_client_config" "current" {}

resource "azuread_application" "ci" {
  display_name = var.display_name
  # Preserves the note Azure DevOps itself wrote when it auto-created this
  # app — dropping it would clear real metadata on a live, in-use identity.
  notes = "Azure DevOps Service Connection sc-shopnest-azure in project https://dev.azure.com/kavitography//shopnest-ado. Managed by Azure DevOps."
}

resource "azuread_service_principal" "ci" {
  client_id = azuread_application.ci.client_id
}

# Issuer/subject below match what Azure DevOps generated on its own when it
# auto-created this app for the sc-shopnest-azure service connection — this
# resource is imported to match reality, not created fresh. If that
# connection is later switched to Workload Identity federation (Manual) and
# Azure DevOps displays a different subject, add a second
# azuread_application_federated_identity_credential rather than editing this
# one, so both stay valid during the transition.
resource "azuread_application_federated_identity_credential" "ado" {
  application_id = azuread_application.ci.id # object ID, not client_id
  # This is ADO's own service-endpoint ID, not a name we chose — matches
  # what Azure DevOps set when it auto-created this credential.
  display_name = "34471a29-d555-483d-be62-866bae025fd0"
  description  = "Federation for Service Connection sc-shopnest-azure in https://dev.azure.com/kavitography/shopnest-ado/_settings/adminservices?resourceId=34471a29-d555-483d-be62-866bae025fd0"
  audiences    = ["api://AzureADTokenExchange"]
  issuer       = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0"
  subject      = "/eid1/c/pub/t/l_g0F9P560GjDGDQktil2A/a/rISbSSETf0KqFyZ8ppdXmA/sc/04bc61ae-3a73-49f9-9620-da217d8cd834/34471a29-d555-483d-be62-866bae025fd0"
}

# The new sc-shopnest-azure-manual service connection (Workload identity
# federation / manual) gets its own internal service-endpoint ID, so it
# needs its own federated credential rather than reusing the one above —
# this subject was read off the AADSTS700213 "no matching federated
# identity record" error returned when verifying that connection before
# this credential existed. Once sc-shopnest-azure-manual is folded back
# into sc-shopnest-azure and this is confirmed as the one actually in use,
# the "ado" credential above (tied to the old Automatic connection) can be
# removed.
resource "azuread_application_federated_identity_credential" "ado_manual" {
  application_id = azuread_application.ci.id
  display_name   = "f0d15987-4107-4cb9-a849-730cc03cc584"
  description    = "Federation for Service Connection sc-shopnest-azure-manual (Workload identity federation, manual)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0"
  subject        = "/eid1/c/pub/t/l_g0F9P560GjDGDQktil2A/a/rISbSSETf0KqFyZ8ppdXmA/sc/04bc61ae-3a73-49f9-9620-da217d8cd834/f0d15987-4107-4cb9-a849-730cc03cc584"
}
