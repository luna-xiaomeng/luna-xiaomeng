const { execSync } = require("child_process");
const result = execSync("openclaw channels login --channel openclaw-weixin 2>&1", {
  cwd: "/home/admin",
  encoding: "utf-8",
  timeout: 60000,
});
console.log(result);
