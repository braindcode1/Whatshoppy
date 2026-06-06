const http = require("http");

function get(url) {
  return new Promise((resolve, reject) => {
    http.get(url, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      });
      res.on("end", () => {
        try {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: JSON.parse(data || "{}")
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data
          });
        }
      });
    }).on("error", reject);
  });
}

async function run() {
  const targetUserId = "a0fadc0d-9a67-43a4-9581-d10c5297e19e";
  
  console.log("Calling GET /api/products...");
  const resProducts = await get(`http://localhost:3000/api/products?user_id=${targetUserId}`);
  console.log("Products response:", JSON.stringify(resProducts, null, 2));

  console.log("\nCalling GET /api/categories...");
  const resCategories = await get(`http://localhost:3000/api/categories?user_id=${targetUserId}`);
  console.log("Categories response:", JSON.stringify(resCategories, null, 2));

  console.log("\nCalling GET /api/clients...");
  const resClients = await get(`http://localhost:3000/api/clients?user_id=${targetUserId}`);
  console.log("Clients response:", JSON.stringify(resClients, null, 2));

  console.log("\nCalling GET /api/dashboard...");
  const resDashboard = await get(`http://localhost:3000/api/dashboard?user_id=${targetUserId}`);
  console.log("Dashboard response:", JSON.stringify(resDashboard, null, 2));
}

run();
