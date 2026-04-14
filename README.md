# Installation

To install the PacedCutscene, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/RedBaren/PacedCutscene.git
   ```
2. Navigate to the project directory:
   ```bash
   cd PacedCutscene
   ```
3. Install dependencies:
   ```bash
   npm install
   ```

# Usage

To use the PacedCutscene, include it in your project and initialize with the desired settings:

```javascript
import PacedCutscene from 'paced-cutscene';

const cutscene = new PacedCutscene({
  // options
});
cutscene.start();
```