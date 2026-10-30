import * as aws from "@pulumi/aws";

// 1. Crear VPC
const vpc = new aws.ec2.Vpc("vpc-pulumi", {
    cidrBlock: "10.0.0.0/16",
    enableDnsHostnames: true,
    enableDnsSupport: true,
});

// 2. Crear Subred Pública
const subnet = new aws.ec2.Subnet("subnet-pulumi", {
    vpcId: vpc.id,
    cidrBlock: "10.0.1.0/24",
    mapPublicIpOnLaunch: true,
});

// 3. Crear Internet Gateway y Tabla de Enrutamiento
const igw = new aws.ec2.InternetGateway("igw-pulumi", { vpcId: vpc.id });
const routeTable = new aws.ec2.RouteTable("rt-pulumi", {
    vpcId: vpc.id,
    routes: [{ cidrBlock: "0.0.0.0/0", gatewayId: igw.id }],
});
new aws.ec2.RouteTableAssociation("rta-pulumi", {
    subnetId: subnet.id,
    routeTableId: routeTable.id,
});

// 4. Crear Grupo de Seguridad
const sg = new aws.ec2.SecurityGroup("sec-group", {
    vpcId: vpc.id,
    ingress: [
        { protocol: "tcp", fromPort: 22, toPort: 22, cidrBlocks: ["0.0.0.0/0"] },
        { protocol: "tcp", fromPort: 3000, toPort: 3000, cidrBlocks: ["0.0.0.0/0"] },
    ],
    egress: [
        { protocol: "-1", fromPort: 0, toPort: 0, cidrBlocks: ["0.0.0.0/0"] }
    ]
});

// 5. Buscar automáticamente la AMI más reciente de Amazon Linux 2023
const ami = aws.ec2.getAmi({
    mostRecent: true,
    owners: ["amazon"],
    filters: [
        { name: "name", values: ["al2023-ami-*-x86_64"] },
        { name: "virtualization-type", values: ["hvm"] },
    ],
});

// 6. UserData (cloud-init) - Usando userDataBase64 para evitar la advertencia
const userDataScript = `#!/bin/bash
dnf update -y
dnf install -y mariadb105-server nodejs git
systemctl enable --now mariadb
mysql -e "CREATE DATABASE IF NOT EXISTS globomatics; CREATE USER IF NOT EXISTS 'globo'@'localhost' IDENTIFIED BY 'secreto123'; GRANT ALL PRIVILEGES ON globomatics.* TO 'globo'@'localhost'; FLUSH PRIVILEGES;"
mysql globomatics -e "CREATE TABLE IF NOT EXISTS tareas (id INT AUTO_INCREMENT PRIMARY KEY, titulo VARCHAR(255) NOT NULL, completada BOOLEAN DEFAULT FALSE); INSERT INTO tareas (titulo, completada) VALUES ('Base de datos inicializada por cloud-init', true), ('Servidor aprovisionado con Pulumi', true);"
`;

// 7. Instancia EC2
const server = new aws.ec2.Instance("servidor-pulumi", {
    instanceType: "t3.micro",
    ami: ami.then(ami => ami.id),
    subnetId: subnet.id,
    vpcSecurityGroupIds: [sg.id],
    userDataBase64: Buffer.from(userDataScript).toString("base64"),
    tags: { Name: "servidor-pulumi" },
});

export const publicIp = server.publicIp;