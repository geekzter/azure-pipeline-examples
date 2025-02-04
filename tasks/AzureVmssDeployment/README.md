Here is a simple flow chart:

```mermaid
graph TD;
    Storage@{ shape: lin-cyl, label: "Storage Account" };
    Pipeline-->|Service Connection| Storage;
    Pipeline-->|Service Connection| VMSS;
    VMSS[Virtual Machine Scale Set]-->|System-assigned MI| Storage;
```
