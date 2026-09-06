import * as core from "@actions/core";

interface HealthResult {
  serverName: string;
  location: string;
  url: string;
  statusCode: number;
  body: string;
  healthy: boolean;
}

async function checkEndpoint(
  serverName: string,
  location: string,
  url: string
): Promise<HealthResult> {
  if (!url) {
    return {
      serverName,
      location,
      url: "N/A",
      statusCode: 0,
      body: "Not configured",
      healthy: true
    };
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000);

    const response = await fetch(url, { signal: controller.signal });
    clearTimeout(timeout);
    const body = await response.text();
    const healthy = response.status >= 200 && response.status < 300;

    return {
      serverName,
      location,
      url,
      statusCode: response.status,
      body,
      healthy
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : "Request failed";
    return {
      serverName,
      location,
      url,
      statusCode: 500,
      body: errorMessage,
      healthy: false
    };
  }
}

async function run(): Promise<void> {
  try {
    const imageTag = core.getInput("image-tag", { required: true });
    const server1Url = core.getInput("server1-url", { required: false });
    const server2Url = core.getInput("server2-url", { required: false });
    const server3Url = core.getInput("server3-url", { required: false });
    const server4Url = core.getInput("server4-url", { required: false });
    const server5Url = core.getInput("server5-url", { required: false });

    core.info("==================================================");
    core.info("  Multi-Cluster DevOps Deployment Verification    ");
    core.info("==================================================");
    core.info(`Image Tag: ${imageTag}`);

    const checks = await Promise.all([
      checkEndpoint("Server 1", "Homelab (rainbowsrv)", server1Url),
      checkEndpoint("Server 2", "Homelab (rainbowsrv)", server2Url),
      checkEndpoint("Server 3", "AWS K3s (NodePort 30003)", server3Url),
      checkEndpoint("Server 4", "AWS K3s (NodePort 30004)", server4Url),
      checkEndpoint("Server 5", "AWS K3s (NodePort 30005)", server5Url)
    ]);

    const activeChecks = checks.filter((c) => c.url !== "N/A");
    const allHealthy = activeChecks.every((c) => c.healthy);

    // Set outputs
    for (const c of checks) {
      const key = `${c.serverName.toLowerCase().replace(" ", "")}-status`;
      core.setOutput(key, c.statusCode.toString());
    }
    core.setOutput("deployment-status", allHealthy ? "success" : "failed");

    // Print individual logs
    core.info("\n--- Service Health Status Logs ---");
    for (const c of activeChecks) {
      if (c.healthy) {
        core.info(`[SUCCESS] ${c.serverName} (${c.location}) is HEALTHY!`);
        core.info(`          URL:      ${c.url}`);
        core.info(`          Status:   HTTP ${c.statusCode}`);
        core.info(`          Response: ${c.body}\n`);
      } else {
        core.error(`[FAILED]  ${c.serverName} (${c.location}) is UNHEALTHY!`);
        core.error(`          URL:      ${c.url}`);
        core.error(`          Status:   HTTP ${c.statusCode}`);
        core.error(`          Response: ${c.body}\n`);
      }
    }

    // Build GitHub step summary table
    const tableHeader: any[] = [
      { data: "Service", header: true },
      { data: "Cluster / Location", header: true },
      { data: "URL", header: true },
      { data: "HTTP Status", header: true },
      { data: "Health", header: true }
    ];

    const tableRows: any[][] = [tableHeader];

    for (const c of activeChecks) {
      tableRows.push([
        c.serverName,
        c.location,
        c.url,
        c.statusCode.toString(),
        c.healthy ? "✅ HEALTHY" : "❌ FAILED"
      ]);
    }

    let responsesCodeBlock = "";
    for (const c of activeChecks) {
      responsesCodeBlock += `// === ${c.serverName} (${c.location}) ===\n// URL: ${c.url}\n${c.body}\n\n`;
    }

    await core.summary
      .addHeading("DevOps Multi-Cluster Deployment Summary", 2)
      .addTable(tableRows)
      .addHeading("Server Responses", 3)
      .addCodeBlock(responsesCodeBlock.trim(), "json")
      .write();

    if (!allHealthy) {
      core.setFailed(
        "One or more server health checks failed across the clusters."
      );
      return;
    }

    core.info("==================================================");
    core.info("  All 5 servers successfully verified & healthy!  ");
    core.info("==================================================");
  } catch (error) {
    if (error instanceof Error) {
      core.setFailed(error.message);
    } else {
      core.setFailed("Unknown error occurred.");
    }
  }
}

run();
