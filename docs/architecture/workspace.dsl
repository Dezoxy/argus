// Entry point for the argus architecture model. This file must stay at
// docs/architecture/: !docs and !adrs paths have to resolve to this directory
// or below it. Model fragments live in model/ and are pulled in with !include,
// in order -- people and outside systems first, then argus's containers, then
// where they run.
workspace "Argus" "Architecture model for argus, an invite-only end-to-end-encrypted messenger. The server is crypto-blind: it stores and forwards ciphertext and holds no key that can read a message." {

    !identifiers hierarchical

    configuration {
        scope softwaresystem
    }

    // Attached to the workspace, not the software system, so both paths
    // resolve unambiguously against this file.
    !docs overview
    !adrs decisions

    properties {
        "structurizr.inspection.model.softwaresystem.documentation" "ignore"
        "structurizr.inspection.model.softwaresystem.decisions" "ignore"
    }

    model {
        !include model/people-systems.dsl
        !include model/containers.dsl
        !include model/deployment.dsl
    }

    views {
        !include model/views.dsl
        !include model/styles.dsl
    }

}
