enum PipelineStage {
  materialRequest,
  poRequested,
  poCreated,
  delivery,
  storekeeperConfirmed,
  installationInProgress,
  installationComplete,
}

enum UserRole { admin, engineer, storekeeper }

enum ProjectStatus { planning, active, onHold, completed }

enum UnitType { villa, apartment, commercial }

enum RequestCategory { furniture, appliance, finishing, other }

enum RequestPriority { low, medium, high, urgent }

enum RecipientType { accounting, supplier, storekeeper }
