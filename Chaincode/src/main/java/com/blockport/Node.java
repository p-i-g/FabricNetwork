package com.blockport;

import com.owlike.genson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;


@DataType
public class Node {
    @Property
    private final String nodeID;
    @Property
    private final String ownerOrg;

    public Node(@JsonProperty("nodeID") String nodeID, String ownerOrg) {
        this.nodeID = nodeID;
        this.ownerOrg = ownerOrg;
    }

    public String getNodeID() {
        return nodeID;
    }

    public String getOwnerOrg() {
        return ownerOrg;
    }
}
