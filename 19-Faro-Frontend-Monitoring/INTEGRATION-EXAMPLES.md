# Frontend Integration Examples

This document provides practical examples of integrating your frontend application with the Faro receiver.

## Table of Contents
1. [React Application](#react-application)
2. [Vue.js Application](#vuejs-application)
3. [Angular Application](#angular-application)
4. [Vanilla JavaScript](#vanilla-javascript)
5. [Source Maps Upload](#source-maps-upload)
6. [CI/CD Integration](#cicd-integration)

---

## React Application

### Installation

```bash
npm install @grafana/faro-web-sdk @grafana/faro-react
```

### Configuration (src/index.js or src/main.tsx)

```javascript
import React from 'react';
import ReactDOM from 'react-dom/client';
import { initializeFaro, ReactIntegration } from '@grafana/faro-react';
import App from './App';

// Initialize Faro - replace with your EC2 instance IP from terraform output
const faro = initializeFaro({
  url: 'http://YOUR_EC2_IP:12345',
  app: {
    name: 'my-react-app',
    version: process.env.REACT_APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV,
  },
  
  // Enable React integration
  integrations: [
    new ReactIntegration(),
  ],
});

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

### Using Faro in Components

```javascript
import { faro } from '@grafana/faro-react';

function MyComponent() {
  const handleClick = () => {
    // Log custom events
    faro.api.pushLog(['Button clicked', 'info']);
    
    // Track custom measurements
    faro.api.pushMeasurement({
      type: 'custom',
      values: {
        button_clicks: 1,
      },
    });
  };

  return <button onClick={handleClick}>Click Me</button>;
}
```

---

## Vue.js Application

### Installation

```bash
npm install @grafana/faro-web-sdk @grafana/faro-vue
```

### Configuration (src/main.js)

```javascript
import { createApp } from 'vue';
import { initializeFaro } from '@grafana/faro-web-sdk';
import { VueIntegration } from '@grafana/faro-vue';
import App from './App.vue';

// Initialize Faro
const faro = initializeFaro({
  url: 'http://YOUR_EC2_IP:12345',
  app: {
    name: 'my-vue-app',
    version: import.meta.env.VITE_APP_VERSION || '1.0.0',
    environment: import.meta.env.MODE,
  },
  integrations: [
    new VueIntegration(),
  ],
});

const app = createApp(App);

// Add Vue integration
const vueIntegration = faro.integrations.vue;
if (vueIntegration) {
  app.use(vueIntegration);
}

app.mount('#app');
```

### Using in Components

```vue
<template>
  <button @click="trackEvent">Track Event</button>
</template>

<script>
import { faro } from '@grafana/faro-web-sdk';

export default {
  methods: {
    trackEvent() {
      faro.api.pushLog(['Vue button clicked', 'info']);
    },
  },
};
</script>
```

---

## Angular Application

### Installation

```bash
npm install @grafana/faro-web-sdk @grafana/faro-angular
```

### Configuration (src/main.ts)

```typescript
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { initializeFaro } from '@grafana/faro-web-sdk';
import { AngularIntegration } from '@grafana/faro-angular';
import { AppModule } from './app/app.module';
import { environment } from './environments/environment';

// Initialize Faro
initializeFaro({
  url: 'http://YOUR_EC2_IP:12345',
  app: {
    name: 'my-angular-app',
    version: environment.version || '1.0.0',
    environment: environment.production ? 'production' : 'development',
  },
  integrations: [
    new AngularIntegration(),
  ],
});

platformBrowserDynamic()
  .bootstrapModule(AppModule)
  .catch(err => console.error(err));
```

### Using in Services

```typescript
import { Injectable } from '@angular/core';
import { faro } from '@grafana/faro-web-sdk';

@Injectable({
  providedIn: 'root',
})
export class MonitoringService {
  logEvent(message: string, level: 'info' | 'warn' | 'error' = 'info') {
    faro.api.pushLog([message, level]);
  }

  trackMetric(name: string, value: number) {
    faro.api.pushMeasurement({
      type: 'custom',
      values: {
        [name]: value,
      },
    });
  }
}
```

---

## Vanilla JavaScript

### Installation

```bash
npm install @grafana/faro-web-sdk
```

### Configuration (index.html or app.js)

```javascript
import { initializeFaro } from '@grafana/faro-web-sdk';

const faro = initializeFaro({
  url: 'http://YOUR_EC2_IP:12345',
  app: {
    name: 'my-vanilla-app',
    version: '1.0.0',
    environment: 'production',
  },
});

// Log custom events
document.getElementById('myButton').addEventListener('click', () => {
  faro.api.pushLog(['Button clicked by user', 'info']);
});

// Capture errors manually
window.addEventListener('error', (event) => {
  faro.api.pushError(event.error);
});
```

### CDN Usage (No Build Step)

```html
<!DOCTYPE html>
<html>
<head>
  <title>My App</title>
  <script src="https://cdn.jsdelivr.net/npm/@grafana/faro-web-sdk/dist/bundle/faro-web-sdk.iife.js"></script>
</head>
<body>
  <h1>My Application</h1>
  <button id="trackBtn">Track Event</button>

  <script>
    // Initialize Faro
    const faro = window.GrafanaFaroWebSdk.initializeFaro({
      url: 'http://YOUR_EC2_IP:12345',
      app: {
        name: 'cdn-app',
        version: '1.0.0',
      },
    });

    // Track events
    document.getElementById('trackBtn').addEventListener('click', () => {
      faro.api.pushLog(['Button clicked', 'info']);
    });
  </script>
</body>
</html>
```

---

## Source Maps Upload

### Option 1: Manual Upload via AWS CLI

```bash
# Install AWS CLI if not already installed
# pip install awscli

# Configure AWS credentials
aws configure

# Upload source maps after build
npm run build
aws s3 cp dist/ s3://YOUR-BUCKET-NAME/ --recursive --exclude "*" --include "*.map"
```

### Option 2: Upload via SSH

```bash
# After building your app
npm run build

# SCP source maps to EC2
scp -i terraform-key.pem dist/*.map ec2-user@YOUR_EC2_IP:/home/ec2-user/

# SSH and move to mounted S3
ssh -i terraform-key.pem ec2-user@YOUR_EC2_IP
sudo mv *.map /mnt/source-maps/
```

### Option 3: Using Node.js Script

Create `upload-sourcemaps.js`:

```javascript
const AWS = require('aws-sdk');
const fs = require('fs');
const path = require('path');
const glob = require('glob');

const s3 = new AWS.S3();
const BUCKET_NAME = 'YOUR-BUCKET-NAME';
const BUILD_DIR = 'dist';

// Find all source maps
const sourceMaps = glob.sync(`${BUILD_DIR}/**/*.map`);

// Upload each source map
Promise.all(
  sourceMaps.map((filePath) => {
    const fileContent = fs.readFileSync(filePath);
    const fileName = path.basename(filePath);

    return s3
      .putObject({
        Bucket: BUCKET_NAME,
        Key: fileName,
        Body: fileContent,
        ContentType: 'application/json',
      })
      .promise()
      .then(() => console.log(`Uploaded: ${fileName}`))
      .catch((err) => console.error(`Error uploading ${fileName}:`, err));
  })
).then(() => console.log('All source maps uploaded!'));
```

Run with:
```bash
node upload-sourcemaps.js
```

---

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy and Upload Source Maps

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build application
        run: npm run build
        env:
          REACT_APP_VERSION: ${{ github.sha }}
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Upload source maps to S3
        run: |
          aws s3 cp dist/ s3://${{ secrets.S3_BUCKET_NAME }}/ \
            --recursive \
            --exclude "*" \
            --include "*.map"
      
      - name: Deploy application
        run: |
          # Your deployment steps here
          echo "Deploy to your hosting provider"
```

### GitLab CI

Create `.gitlab-ci.yml`:

```yaml
stages:
  - build
  - deploy

variables:
  S3_BUCKET: "your-bucket-name"

build:
  stage: build
  image: node:18
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/

deploy:
  stage: deploy
  image: amazon/aws-cli
  script:
    - aws s3 cp dist/ s3://$S3_BUCKET/ --recursive --exclude "*" --include "*.map"
  only:
    - main
```

### Jenkins Pipeline

Create `Jenkinsfile`:

```groovy
pipeline {
  agent any
  
  environment {
    S3_BUCKET = 'your-bucket-name'
    AWS_REGION = 'us-east-1'
  }
  
  stages {
    stage('Install') {
      steps {
        sh 'npm ci'
      }
    }
    
    stage('Build') {
      steps {
        sh 'npm run build'
      }
    }
    
    stage('Upload Source Maps') {
      steps {
        withAWS(credentials: 'aws-credentials', region: env.AWS_REGION) {
          sh '''
            aws s3 cp dist/ s3://${S3_BUCKET}/ \
              --recursive \
              --exclude "*" \
              --include "*.map"
          '''
        }
      }
    }
  }
}
```

---

## Advanced Configuration

### Custom Error Handling

```javascript
import { initializeFaro } from '@grafana/faro-web-sdk';

const faro = initializeFaro({
  url: 'http://YOUR_EC2_IP:12345',
  app: {
    name: 'my-app',
    version: '1.0.0',
  },
  
  // Custom error handling
  beforeSend: (item) => {
    // Filter out sensitive data
    if (item.payload && item.payload.message) {
      item.payload.message = item.payload.message.replace(/password=\w+/g, 'password=***');
    }
    return item;
  },
  
  // Ignore specific errors
  ignoreErrors: [
    'ResizeObserver loop limit exceeded',
    /Script error\.?/,
  ],
});
```

### User Context

```javascript
// Set user context
faro.api.setUser({
  id: '12345',
  username: 'john_doe',
  email: 'john@example.com',
});

// Add session attributes
faro.api.pushEvent('session_start', {
  plan: 'premium',
  feature_flags: ['new_ui', 'beta_feature'],
});
```

### Performance Monitoring

```javascript
// Track page load time
window.addEventListener('load', () => {
  const perfData = performance.timing;
  const pageLoadTime = perfData.loadEventEnd - perfData.navigationStart;
  
  faro.api.pushMeasurement({
    type: 'custom',
    values: {
      page_load_time: pageLoadTime,
    },
  });
});

// Track API calls
async function fetchData(url) {
  const startTime = performance.now();
  
  try {
    const response = await fetch(url);
    const endTime = performance.now();
    
    faro.api.pushMeasurement({
      type: 'custom',
      values: {
        api_call_duration: endTime - startTime,
      },
    });
    
    return response;
  } catch (error) {
    faro.api.pushError(error);
    throw error;
  }
}
```

---

## Testing

### Test in Development

```javascript
// Use environment variable
const faroUrl = process.env.REACT_APP_FARO_URL || 'http://localhost:12345';

const faro = initializeFaro({
  url: faroUrl,
  app: {
    name: 'my-app',
    version: '1.0.0',
    environment: process.env.NODE_ENV,
  },
});
```

### Verify Data is Being Sent

Open browser DevTools Network tab and filter by "12345" to see requests being sent to Faro.

---

## Troubleshooting

### CORS Issues

If you see CORS errors, verify the Faro receiver configuration allows your origin:

```bash
ssh -i terraform-key.pem ec2-user@YOUR_EC2_IP
cat /opt/faro-receiver/config.alloy
```

The `cors_allowed_origins` should include your domain or use `["*"]` for development.

### No Data Appearing

1. Check browser console for errors
2. Verify the Faro endpoint is accessible: `curl http://YOUR_EC2_IP:12345/healthz`
3. Check Faro receiver logs: `sudo docker logs faro-receiver`

### Source Maps Not Applied

1. Verify source maps are uploaded to S3
2. Check they're accessible at `/mnt/source-maps` on EC2
3. Ensure filenames match exactly

---

## Best Practices

1. **Use Environment Variables**: Never hardcode the Faro URL
2. **Version Your App**: Use git commit SHA as version
3. **Filter Sensitive Data**: Use `beforeSend` to remove PII
4. **Upload Source Maps**: Always upload after production builds
5. **Monitor Costs**: Keep an eye on data volume and AWS costs
6. **Test in Staging**: Verify integration in staging environment first

## Resources

- [Faro Web SDK Documentation](https://grafana.com/docs/faro/latest/sources/web-sdk/)
- [Faro React Integration](https://grafana.com/docs/faro/latest/sources/react/)
- [Faro Vue Integration](https://grafana.com/docs/faro/latest/sources/vue/)
