Here is a simple flow chart:

```mermaid
graph TD;
    Storage@{ shape: lin-cyl, label: "Disk storage" };
    Pipeline-->|Service Connection| Storage;
    Pipeline-->|Service Connection| VMSS;
    VMSS-->|System-assigned MI| Storage;
```
