# 2026-07-13 Session Retrospective: Phase 5 Code Reading

## Goal

Read the Phase 5 Terraform code closely enough to explain why it was split into
modules, how the environment wrappers compose those modules, and how Terraform
preserves existing resources during the refactor.

## Why Modules Help

Phase 5 is a refactor: it changes the Terraform code structure without
intentionally changing the Azure architecture.

The split creates matching boundaries in several places:

```text
Code                    Terraform plan addresses     Main responsibility
----------------------  ---------------------------  -------------------
modules/network/        module.network.*             Network resources
modules/linux-vm/       module.linux_vm.*            Linux VM
environments/dev/       Root module                  Dev composition
```

These boundaries make it easier to:

- reuse the same implementation in `dev`, `staging`, and `prod`;
- review only the network or VM implementation in a Git diff;
- identify the affected area from addresses in a complete Terraform plan;
- assign code review responsibility by directory; and
- keep each environment entry point focused on high-level composition.

A module boundary improves visibility and ownership, but it is not
automatically an independent deployment or access-control boundary. The
network and VM modules in one environment still share the same root module and
Terraform state.

## The Environment Wrapper

Each environment `main.tf` calls the reusable modules and connects their
interfaces. For example, the Linux VM call receives values produced by the
network module:

```hcl
resource_group_name  = module.network.resource_group_name
network_interface_id = module.network.network_interface_id
```

The complete value flow is:

```text
Network resources
  -> modules/network/outputs.tf
  -> environments/<environment>/main.tf
  -> modules/linux-vm/variables.tf
  -> Linux VM resource
```

These references pass values and also create an implicit dependency from
`module.linux_vm` to `module.network`. An explicit `depends_on` is not needed
for the Resource Group and NIC relationship.

The wrapper code looks similar across all environments, but keeping separate
root modules allows intentional differences. For example, a new staging
environment could initially call only the network module and add the VM module
later. Removing or commenting out an already-applied VM module is different:
Terraform interprets that as a request to destroy the VM, not as a temporary
pause.

Each root module also accepts its own `subscription_id`. This permits dev,
staging, and prod to use separate Azure subscriptions for stronger RBAC,
policy, billing, and blast-radius boundaries. The code permits this separation
but does not require the IDs to be different.

## Planning Module Changes

A normal plan should cover the complete environment:

```bash
terraform -chdir=environments/dev plan
```

Expected result: Terraform evaluates the whole dev dependency graph, while
resource addresses such as `module.network.*` and `module.linux_vm.*` make the
affected module visible.

Reason: module addresses help classify changes without hiding possible effects
across module boundaries.

Targeted plans are technically possible:

```bash
terraform -chdir=environments/dev plan -target=module.network
```

They are intended for exceptional troubleshooting rather than the normal
workflow. A targeted plan can omit relevant changes elsewhere in the root
module, and targeting the VM can still include resources it depends on.

## What `moved` Blocks Do

Terraform matches configuration to state using resource addresses. Moving an
existing resource into a module changes its address even when the Azure object
and its arguments stay the same:

```text
azurerm_virtual_network.main
-> module.network.azurerm_virtual_network.main
```

Without an explicit mapping, Terraform can interpret this as deletion at the
old address and creation at the new address. A `moved` block tells Terraform
that both addresses represent the same managed object:

```hcl
moved {
  from = azurerm_virtual_network.main
  to   = module.network.azurerm_virtual_network.main
}
```

The block changes Terraform's state address during apply; it does not move the
VNet to another Azure region, Resource Group, or subscription.

The ideal Phase 5 migration plan therefore shows address moves with no
unintended resource creation, replacement, or destruction.

## Keeping And Removing Move History

After every relevant state has applied the move, the state already contains the
new addresses. Removing the corresponding blocks can then be technically safe
for a private configuration when all environments and workspaces are known to
have migrated.

Keeping historical blocks preserves an upgrade path for states that have not
yet applied an intermediate version. This is especially important for shared
or published modules. In this learning repository, keeping them also records
the Phase 5 refactor, while the separate `moved.tf` files keep the main
composition readable.

Repeated one-way moves can be chained:

```hcl
moved {
  from = azurerm_public_ip.main
  to   = module.network.azurerm_public_ip.main
}

moved {
  from = module.network.azurerm_public_ip.main
  to   = module.public_ip.azurerm_public_ip.main
}
```

This supports states from either earlier address. `moved` blocks are
declarative and do not run from top to bottom, so opposite mappings cannot be
kept as an executable history:

```text
A -> B -> A  (cycle)
```

If a resource is moved back from `B` to its original address `A`, the active
mapping becomes `B -> A`. States already at `A` require no move, while states
at `B` can return safely. Git history, PR descriptions, or session notes record
why the design moved forward and then back.

## Understanding Reached

The Phase 5 code can now be explained in terms of:

- reusable module implementation versus environment composition;
- inputs and outputs as module interfaces;
- implicit dependencies created by references;
- Git and Terraform address boundaries for review;
- module boundaries versus state and deployment boundaries;
- state-safe address migration with `moved`; and
- environment-specific module and subscription choices.

This is enough foundation to continue to Phase 6. Identity and RBAC changes
will provide the next practical exercise in deciding which module owns a
resource and which IDs must cross module interfaces.

## Validation

This was a code-reading and documentation session. No Terraform configuration
was changed, and no `terraform plan`, `terraform apply`, or `terraform destroy`
was run.
