//
//  PreviewData.swift
//  Containers
//
//  Created by Amitosh Swain Mahapatra on 11/04/25.
//

import Foundation

class PreviewData {
    static let container = Container(
        id: "abcdef123456",
        names: ["/sample-container"],
        image: "nginx:latest",
        imageId: "sha256:123456abcdef",
        command: "/docker-entrypoint.sh nginx -g 'daemon off;'",
        created: Int(Date().timeIntervalSince1970 - 86400),
        status: "Up 2 hours",
        state: .running,
        ports: [
            Container.Port(
                ip: "0.0.0.0",
                privatePort: 80,
                publicPort: 8080,
                type: "tcp"
            )
        ],
        labels: ["com.docker.compose.project": "sample", "maintainer": "NGINX Docker Maintainers"],
        sizeRw: 1024,
        sizeRootFs: 102400
    )

    static let image = ContainerImage(
        id: "sha256:a8780b506fa4eeb1c0779a3d5010f263a50b3c5bf3e8d64c5c22c48e09c17e9b",
        parentId: "sha256:9edd8162a0facbffee54f9f0b9d5c2f3b02e317160c3a972d8e6d1480e5b4e92",
        repoTags: ["nginx:latest", "nginx:1.21"],
        repoDigests: ["nginx@sha256:12345abcdef"],
        created: Int(Date().timeIntervalSince1970 - 86400),
        size: 133_284_859,
        sharedSize: 12_976_689,
        labels: ["maintainer": "NGINX Docker Maintainers"],
        containers: 2
    )

    static let network = Network(
        id: "12345abcdef",
        name: "bridge",
        driver: "bridge",
        scope: "local",
        ipam: Network.IPAM(
            driver: "default",
            config: [
                Network.IPAM.IPAMConfig(
                    subnet: "172.17.0.0/16",
                    gateway: "172.17.0.1",
                    ipRange: nil
                )
            ],
            options: nil
        ),
        containers: [
            "container1": Network.NetworkContainer(
                name: "web_server",
                endpointId: "endpoint1",
                macAddress: "02:42:ac:11:00:02",
                ipv4Address: "172.17.0.2/16",
                ipv6Address: nil
            )
        ],
        options: ["com.docker.network.bridge.default_bridge": "true"],
        labels: ["com.example.network": "primary"],
        isInternal: false,
        created: "2023-03-13T10:20:30.123456789Z"
    )

    static let volume = Volume(
        name: "app_data",
        driver: "local",
        mountpoint: "/var/lib/docker/volumes/app_data/_data",
        createdAt: "2023-03-13T10:20:30Z",
        status: ["Status": "Active"],
        labels: ["com.example.description": "Application Data"],
        scope: "local",
        options: ["type": "nfs"],
        usageData: Volume.UsageData(size: 1_024_000, refCount: 2)
    )

    static let dockerInfo = DockerInfo(
        id: "ABCD:EFGH:IJKL:MNOP:QRST:UVWX:YZ01:2345",
        containers: 3,
        containersRunning: 2,
        containersPaused: 0,
        containersStopped: 1,
        images: 5,
        driver: "overlay2",
        memoryLimit: true,
        swapLimit: true,
        kernelMemoryTCP: true,
        cpuCfsPeriod: true,
        cpuCfsQuota: true,
        cpuShares: true,
        cpuSet: true,
        pidsLimit: true,
        ipv4Forwarding: true,
        bridgeNfIptables: true,
        bridgeNfIp6tables: true,
        debug: false,
        nfd: 32,
        oomKillDisable: true,
        nGoroutines: 86,
        systemTime: ISO8601DateFormatter().string(from: Date()),
        loggingDriver: "json-file",
        cgroupDriver: "systemd",
        cgroupVersion: "2",
        nEventsListener: 0,
        kernelVersion: "5.15.0-1033-azure",
        operatingSystem: "macOS",
        osVersion: "13.6",
        osType: "darwin",
        architecture: "arm64",
        indexServerAddress: "https://index.docker.io/v1/",
        registryConfig: RegistryConfig(
            allowNondistributableArtifactsCIDRs: [],
            allowNondistributableArtifactsHostnames: [],
            insecureRegistryCIDRs: ["127.0.0.0/8"],
            indexConfigs: [
                "docker.io": IndexConfig(
                    name: "docker.io",
                    mirrors: [],
                    secure: true,
                    official: true
                )
            ],
            mirrors: []
        ),
        ncpu: 8,
        memTotal: 16_777_216_000,
        genericResources: nil,
        dockerRootDir: "/var/lib/docker",
        httpProxy: nil,
        httpsProxy: nil,
        noProxy: nil,
        name: "docker-desktop",
        labels: [],
        experimentalBuild: false,
        serverVersion: "24.0.6",
        runtimes: [
            "runc": Runtime(
                path: "runc",
                runtimeArgs: nil
            )
        ],
        defaultRuntime: "runc",
        swarm: SwarmInfo(
            nodeID: "",
            nodeAddr: "",
            localNodeState: "inactive",
            controlAvailable: false,
            error: "",
            remoteManagers: nil,
            nodes: nil,
            managers: nil,
            cluster: nil
        ),
        liveRestoreEnabled: false,
        isolation: "default",
        initBinary: "docker-init",
        containerdCommit: Commit(
            id: "a4d1455758466e815b8b3c107fbd036bc868c528",
            expected: "a4d1455758466e815b8b3c107fbd036bc868c528"
        ),
        runcCommit: Commit(
            id: "a916309fff0f3a97b92b2396ab834c1826058d1a",
            expected: "a916309fff0f3a97b92b2396ab834c1826058d1a"
        ),
        initCommit: Commit(
            id: "de40ad0",
            expected: "de40ad0"
        ),
        securityOptions: [
            "name=seccomp,profile=builtin",
            "name=rootless"
        ],
        warnings: nil
    )
}
