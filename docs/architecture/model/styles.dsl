// argus's layer mapping onto the approved palette. styles-shared.dsl defines
// what a colour MEANS; this file only says which layer takes which family.
// No raw colour codes here, and none of the shared tags are redefined.
//
// Tag order matters on an element: layer tag first, security marking last.
//
//   Edge    purple   what faces outside
//   App     teal     what runs the product
//   Data    green    what remembers
//   Ops     magenta  what maintains
//   Obs     slate    what watches

styles {
    !include styles-shared.dsl

    // Edge: what faces outside.
    element "Layer Edge" {
        background ${PURPLE_FILL}
        stroke ${PURPLE_STROKE}
    }
    element "Group:Edge" {
        color ${PURPLE_LABEL}
        stroke ${PURPLE_STROKE}
        background ${PURPLE_FRAME}
    }
    relationship "Layer Edge" {
        color ${PURPLE_STROKE}
    }

    // App: what runs the product.
    element "Layer App" {
        background ${TEAL_FILL}
        stroke ${TEAL_STROKE}
    }
    element "Group:Application" {
        color ${TEAL_LABEL}
        stroke ${TEAL_STROKE}
        background ${TEAL_FRAME}
    }
    relationship "Layer App" {
        color ${TEAL_STROKE}
    }

    // Data: what remembers.
    element "Layer Data" {
        background ${GREEN_FILL}
        stroke ${GREEN_STROKE}
    }
    element "Group:Data" {
        color ${GREEN_LABEL}
        stroke ${GREEN_STROKE}
        background ${GREEN_FRAME}
    }
    relationship "Layer Data" {
        color ${GREEN_STROKE}
    }

    // Ops: what maintains.
    element "Layer Ops" {
        background ${MAGENTA_FILL}
        stroke ${MAGENTA_STROKE}
    }
    element "Group:Maintenance" {
        color ${MAGENTA_LABEL}
        stroke ${MAGENTA_STROKE}
        background ${MAGENTA_FRAME}
    }
    relationship "Layer Ops" {
        color ${MAGENTA_STROKE}
    }

    // Obs: what watches.
    element "Layer Obs" {
        background ${SLATE_FILL}
        stroke ${SLATE_STROKE}
    }
    element "Group:Observability" {
        color ${SLATE_LABEL}
        stroke ${SLATE_STROKE}
        background ${SLATE_FRAME}
    }
    relationship "Layer Obs" {
        color ${SLATE_STROKE}
    }

}
