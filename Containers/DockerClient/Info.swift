//
//  Info.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 13/04/25.
//

struct DockerInfo: Codable {
    let id: String
    let containers: Int
    let containersRunning: Int
    let containersPaused: Int
    let containersStopped: Int
    let images: Int
    let driver: String
    let memoryLimit: Bool
    let swapLimit: Bool
    let kernelMemoryTCP: Bool?
    let cpuCfsPeriod: Bool
    let cpuCfsQuota: Bool
    let cpuShares: Bool
    let cpuSet: Bool
    let pidsLimit: Bool
    let ipv4Forwarding: Bool
    let bridgeNfIptables: Bool
    let bridgeNfIp6tables: Bool
    let debug: Bool
    let nfd: Int
    let oomKillDisable: Bool
    let nGoroutines: Int
    let systemTime: String
    let loggingDriver: String
    let cgroupDriver: String
    let cgroupVersion: String?
    let nEventsListener: Int
    let kernelVersion: String
    let operatingSystem: String
    let osVersion: String?
    let osType: String
    let architecture: String
    let indexServerAddress: String
    let registryConfig: RegistryConfig
    let ncpu: Int
    let memTotal: Int64
    let genericResources: [String]?
    let dockerRootDir: String
    let httpProxy: String?
    let httpsProxy: String?
    let noProxy: String?
    let name: String
    let labels: [String]?
    let experimentalBuild: Bool
    let serverVersion: String
    let runtimes: [String: Runtime]
    let defaultRuntime: String
    let swarm: SwarmInfo
    let liveRestoreEnabled: Bool
    let isolation: String?
    let initBinary: String
    let containerdCommit: Commit
    let runcCommit: Commit
    let initCommit: Commit
    let securityOptions: [String]
    let warnings: [String]?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case containers = "Containers"
        case containersRunning = "ContainersRunning"
        case containersPaused = "ContainersPaused"
        case containersStopped = "ContainersStopped"
        case images = "Images"
        case driver = "Driver"
        case memoryLimit = "MemoryLimit"
        case swapLimit = "SwapLimit"
        case kernelMemoryTCP = "KernelMemoryTCP"
        case cpuCfsPeriod = "CpuCfsPeriod"
        case cpuCfsQuota = "CpuCfsQuota"
        case cpuShares = "CPUShares"
        case cpuSet = "CPUSet"
        case pidsLimit = "PidsLimit"
        case ipv4Forwarding = "IPv4Forwarding"
        case bridgeNfIptables = "BridgeNfIptables"
        case bridgeNfIp6tables = "BridgeNfIp6tables"
        case debug = "Debug"
        case nfd = "NFd"
        case oomKillDisable = "OomKillDisable"
        case nGoroutines = "NGoroutines"
        case systemTime = "SystemTime"
        case loggingDriver = "LoggingDriver"
        case cgroupDriver = "CgroupDriver"
        case cgroupVersion = "CgroupVersion"
        case nEventsListener = "NEventsListener"
        case kernelVersion = "KernelVersion"
        case operatingSystem = "OperatingSystem"
        case osVersion = "OSVersion"
        case osType = "OSType"
        case architecture = "Architecture"
        case indexServerAddress = "IndexServerAddress"
        case registryConfig = "RegistryConfig"
        case ncpu = "NCPU"
        case memTotal = "MemTotal"
        case genericResources = "GenericResources"
        case dockerRootDir = "DockerRootDir"
        case httpProxy = "HttpProxy"
        case httpsProxy = "HttpsProxy"
        case noProxy = "NoProxy"
        case name = "Name"
        case labels = "Labels"
        case experimentalBuild = "ExperimentalBuild"
        case serverVersion = "ServerVersion"
        case runtimes = "Runtimes"
        case defaultRuntime = "DefaultRuntime"
        case swarm = "Swarm"
        case liveRestoreEnabled = "LiveRestoreEnabled"
        case isolation = "Isolation"
        case initBinary = "InitBinary"
        case containerdCommit = "ContainerdCommit"
        case runcCommit = "RuncCommit"
        case initCommit = "InitCommit"
        case securityOptions = "SecurityOptions"
        case warnings = "Warnings"
    }
}

struct RegistryConfig: Codable {
    let allowNondistributableArtifactsCIDRs: [String]?
    let allowNondistributableArtifactsHostnames: [String]?
    let insecureRegistryCIDRs: [String]?
    let indexConfigs: [String: IndexConfig]
    let mirrors: [String]?

    enum CodingKeys: String, CodingKey {
        case allowNondistributableArtifactsCIDRs = "AllowNondistributableArtifactsCIDRs"
        case allowNondistributableArtifactsHostnames = "AllowNondistributableArtifactsHostnames"
        case insecureRegistryCIDRs = "InsecureRegistryCIDRs"
        case indexConfigs = "IndexConfigs"
        case mirrors = "Mirrors"
    }
}

struct IndexConfig: Codable {
    let name: String
    let mirrors: [String]?
    let secure: Bool
    let official: Bool

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case mirrors = "Mirrors"
        case secure = "Secure"
        case official = "Official"
    }
}

struct Runtime: Codable {
    let path: String
    let runtimeArgs: [String]?

    enum CodingKeys: String, CodingKey {
        case path = "path"
        case runtimeArgs = "runtimeArgs"
    }
}

struct SwarmInfo: Codable {
    let nodeID: String?
    let nodeAddr: String?
    let localNodeState: String
    let controlAvailable: Bool?
    let error: String?
    let remoteManagers: [RemoteManager]?
    let nodes: Int?
    let managers: Int?
    let cluster: ClusterInfo?

    enum CodingKeys: String, CodingKey {
        case nodeID = "NodeID"
        case nodeAddr = "NodeAddr"
        case localNodeState = "LocalNodeState"
        case controlAvailable = "ControlAvailable"
        case error = "Error"
        case remoteManagers = "RemoteManagers"
        case nodes = "Nodes"
        case managers = "Managers"
        case cluster = "Cluster"
    }
}

struct RemoteManager: Codable {
    let nodeID: String
    let addr: String

    enum CodingKeys: String, CodingKey {
        case nodeID = "NodeID"
        case addr = "Addr"
    }
}

struct ClusterInfo: Codable {
    let id: String
    let version: Version
    let createdAt: String
    let updatedAt: String
    let spec: ClusterSpec
    let tlsInfo: TLSInfo
    let rootRotationInProgress: Bool
    let dataPathPort: Int
    let defaultAddrPool: [String]
    let subnetSize: Int

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case version = "Version"
        case createdAt = "CreatedAt"
        case updatedAt = "UpdatedAt"
        case spec = "Spec"
        case tlsInfo = "TLSInfo"
        case rootRotationInProgress = "RootRotationInProgress"
        case dataPathPort = "DataPathPort"
        case defaultAddrPool = "DefaultAddrPool"
        case subnetSize = "SubnetSize"
    }
}

struct Version: Codable {
    let index: Int

    enum CodingKeys: String, CodingKey {
        case index = "Index"
    }
}

struct ClusterSpec: Codable {
    let name: String
    let labels: [String: String]?
    let orchestration: Orchestration
    let raft: Raft
    let dispatcher: Dispatcher
    let caConfig: CAConfig
    let encryptionConfig: EncryptionConfig
    let taskDefaults: TaskDefaults

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case labels = "Labels"
        case orchestration = "Orchestration"
        case raft = "Raft"
        case dispatcher = "Dispatcher"
        case caConfig = "CAConfig"
        case encryptionConfig = "EncryptionConfig"
        case taskDefaults = "TaskDefaults"
    }
}

struct Orchestration: Codable {
    let taskHistoryRetentionLimit: Int

    enum CodingKeys: String, CodingKey {
        case taskHistoryRetentionLimit = "TaskHistoryRetentionLimit"
    }
}

struct Raft: Codable {
    let snapshotInterval: Int
    let keepOldSnapshots: Int
    let logEntriesForSlowFollowers: Int
    let electionTick: Int
    let heartbeatTick: Int

    enum CodingKeys: String, CodingKey {
        case snapshotInterval = "SnapshotInterval"
        case keepOldSnapshots = "KeepOldSnapshots"
        case logEntriesForSlowFollowers = "LogEntriesForSlowFollowers"
        case electionTick = "ElectionTick"
        case heartbeatTick = "HeartbeatTick"
    }
}

struct Dispatcher: Codable {
    let heartbeatPeriod: Int64

    enum CodingKeys: String, CodingKey {
        case heartbeatPeriod = "HeartbeatPeriod"
    }
}

struct CAConfig: Codable {
    let nodeCertExpiry: Int64
    let externalCAs: [ExternalCA]?
    let signingCACert: String?
    let signingCAKey: String?
    let forceRotate: Int?

    enum CodingKeys: String, CodingKey {
        case nodeCertExpiry = "NodeCertExpiry"
        case externalCAs = "ExternalCAs"
        case signingCACert = "SigningCACert"
        case signingCAKey = "SigningCAKey"
        case forceRotate = "ForceRotate"
    }
}

struct ExternalCA: Codable {
    let `protocol`: String
    let url: String
    let options: [String: String]?
    let caHash: String?

    enum CodingKeys: String, CodingKey {
        case `protocol` = "Protocol"
        case url = "URL"
        case options = "Options"
        case caHash = "CACert"
    }
}

struct EncryptionConfig: Codable {
    let autoLockManagers: Bool

    enum CodingKeys: String, CodingKey {
        case autoLockManagers = "AutoLockManagers"
    }
}

struct TaskDefaults: Codable {
    let logDriver: LogDriverConfig?

    enum CodingKeys: String, CodingKey {
        case logDriver = "LogDriver"
    }
}

struct LogDriverConfig: Codable {
    let name: String
    let options: [String: String]?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case options = "Options"
    }
}

struct TLSInfo: Codable {
    let trustRoot: String?
    let certIssuerSubject: String?
    let certIssuerPublicKey: String?

    enum CodingKeys: String, CodingKey {
        case trustRoot = "TrustRoot"
        case certIssuerSubject = "CertIssuerSubject"
        case certIssuerPublicKey = "CertIssuerPublicKey"
    }
}

struct Commit: Codable {
    let id: String
    let expected: String

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case expected = "Expected"
    }
}
