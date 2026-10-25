import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as fs from "fs";
import * as path from "path";

// 1. Obtener la AMI de Amazon Linux 2023
const ami = aws.ec2.getAmi({
    mostRecent: true,
    owners: ["amazon"],
    filters: [{ name: "name", values: ["al2023-ami-2023.*-x86_64"] }],
});

// 2. Crear Grupo de Seguridad
const sg = new aws.ec2.SecurityGroup("globomatics-sg", {
    description: "Acceso web y SSH",
    ingress: [
        { protocol: "tcp", fromPort: 3000, toPort: 3000, cidrBlocks: ["0.0.0.0/0"] },
        { protocol: "tcp", fromPort: 22, toPort: 22, cidrBlocks: ["0.0.0.0/0"] },
    ],
    egress: [{ protocol: "-1", fromPort: 0, toPort: 0, cidrBlocks: ["0.0.0.0/0"] }],
});

// 3. Leer y preparar el cloud-init
const cloudInitPath = path.join(__dirname, "../cloud-init.yaml");
const cloudInitContent = fs.readFileSync(cloudInitPath, "utf8");

// 4. Crear la Instancia EC2
const server = new aws.ec2.Instance("globomatics-server", {
    ami: ami.then(ami => ami.id),
    instanceType: "t3.micro",
    vpcSecurityGroupIds: [sg.id],
    userData: cloudInitContent,
    tags: { Name: "servidor-pulumi-cloudinit" },
});

// 5. Outputs para ver la URL al finalizar
export const instanciaId = server.id;
export const urlApp = pulumi.interpolate`http://${server.publicIp}:3000`;