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

    core.info("========================================");
    core.info("TypeScript DevOps Deployment Action");
    core.info("========================================");

    core.info(`Image: ${imageTag}`);
    core.info(`Server 1: ${server1Url}`);
    core.info(`Server 2: ${server2Url}`);

    const [server1, server2] = await Promise.all([
      checkEndpoint(server1Url),
      checkEndpoint(server2Url)
    ]);

    const server1Healthy = server1.statusCode >= 200 &&
      server1.statusCode < 300;

    const server2Healthy = server2.statusCode >= 200 &&
      server2.statusCode < 300;

    core.setOutput(
      "server1-status",
      server1.statusCode.toString()
    );

    core.setOutput(
      "server2-status",
      server2.statusCode.toString()
    );

    const deploymentSuccessful =
      server1Healthy && server2Healthy;

    core.setOutput(
      "deployment-status",
      deploymentSuccessful ? "success" : "failed"
    );

    await core.summary
      .addHeading("DevOps Deployment Summary")
      .addTable([
        [
          { data: "Property", header: true },
          { data: "Value", header: true }
        ],
        ["Image", imageTag],
        ["Server 1 HTTP", server1.statusCode.toString()],
        ["Server 2 HTTP", server2.statusCode.toString()],
        ["Overall Status", deploymentSuccessful ? "SUCCESS" : "FAILED"]
      ])
      .addHeading("Server Responses")
      .addCodeBlock(
        `Server 1:\n${server1.body}\n\nServer 2:\n${server2.body}`,
        "json"
      )
      .write();

    core.info(`Server 1: HTTP ${server1.statusCode}`);
    core.info(`Server 2: HTTP ${server2.statusCode}`);

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
