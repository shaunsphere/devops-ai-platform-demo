import * as core from "@actions/core";

interface HealthResult {
  statusCode: number;
  body: string;
}

async function checkEndpoint(url: string): Promise<HealthResult> {
  const response = await fetch(url);

  const body = await response.text();

  return {
    statusCode: response.status,
    body
  };
}

async function run(): Promise<void> {
  try {
    const imageTag = core.getInput("image-tag", {
      required: true
    });

    const server1Url = core.getInput("server1-url", {
      required: true
    });

    const server2Url = core.getInput("server2-url", {
      required: true
    });

    const server3Url = core.getInput("server3-url", {
      required: false
    });

    core.info("========================================");
    core.info("TypeScript DevOps Deployment Action");
    core.info("========================================");

    core.info(`Image: ${imageTag}`);
    core.info(`Server 1: ${server1Url}`);
    core.info(`Server 2: ${server2Url}`);
    if (server3Url) {
      core.info(`Server 3 (AWS): ${server3Url}`);
    }

    const checkPromises: [
      Promise<HealthResult>,
      Promise<HealthResult>,
      Promise<HealthResult | null>
    ] = [
      checkEndpoint(server1Url),
      checkEndpoint(server2Url),
      server3Url ? checkEndpoint(server3Url) : Promise.resolve(null)
    ];

    const [server1, server2, server3] = await Promise.all(checkPromises);

    const server1Healthy =
      server1.statusCode >= 200 && server1.statusCode < 300;

    const server2Healthy =
      server2.statusCode >= 200 && server2.statusCode < 300;

    const server3Healthy = server3
      ? server3.statusCode >= 200 && server3.statusCode < 300
      : true;

    core.setOutput("server1-status", server1.statusCode.toString());
    core.setOutput("server2-status", server2.statusCode.toString());
    if (server3) {
      core.setOutput("server3-status", server3.statusCode.toString());
    }

    const deploymentSuccessful =
      server1Healthy && server2Healthy && server3Healthy;

    core.setOutput(
      "deployment-status",
      deploymentSuccessful ? "success" : "failed"
    );

    const tableRows = [
      [
        { data: "Property", header: true },
        { data: "Value", header: true }
      ],
      ["Image", imageTag],
      ["Server 1 HTTP (Homelab)", server1.statusCode.toString()],
      ["Server 2 HTTP (Homelab)", server2.statusCode.toString()]
    ];

    if (server3) {
      tableRows.push([
        "Server 3 HTTP (AWS EC2)",
        server3.statusCode.toString()
      ]);
    }

    tableRows.push([
      "Overall Status",
      deploymentSuccessful ? "SUCCESS" : "FAILED"
    ]);

    let responseSummary = `Server 1:\n${server1.body}\n\nServer 2:\n${server2.body}`;
    if (server3) {
      responseSummary += `\n\nServer 3 (AWS):\n${server3.body}`;
    }

    await core.summary
      .addHeading("DevOps Deployment Summary")
      .addTable(tableRows)
      .addHeading("Server Responses")
      .addCodeBlock(responseSummary, "json")
      .write();

    core.info(`Server 1: HTTP ${server1.statusCode}`);
    core.info(`Server 2: HTTP ${server2.statusCode}`);
    if (server3) {
      core.info(`Server 3 (AWS): HTTP ${server3.statusCode}`);
    }

    if (!deploymentSuccessful) {
      core.setFailed("One or more deployment health checks failed.");
      return;
    }

    core.info("Deployment verification succeeded.");
  } catch (error) {
    if (error instanceof Error) {
      core.setFailed(error.message);
    } else {
      core.setFailed("Unknown error occurred.");
    }
  }
}

run();
