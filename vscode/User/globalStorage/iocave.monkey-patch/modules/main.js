require.config({
    paths: {
        "customize-ui" : "/Users/xavier/Library/Application Support/Code/User/globalStorage/iocave.customize-ui/modules",
        "monkey-generated" : "/Users/xavier/Library/Application Support/Code/User/globalStorage/iocave.monkey-patch/modules"
    }
});

define(["monkey-generated/entrypoint-main", "customize-ui/title-bar-main-process"], function (){});