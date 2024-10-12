package com.blockport;

import com.owlike.genson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;


@DataType()
public class IDCounter {
    @Property
    private final int nextShipmentID;
    @Property
    private final int nextNodeID;

    public IDCounter(@JsonProperty("nextShipmentID") int nextShipmentID, @JsonProperty("nextNodeID") int nextNodeID) {
        this.nextShipmentID = nextShipmentID;
        this.nextNodeID = nextNodeID;
    }

    public int getNextShipmentID() {
        return nextShipmentID;
    }

    public int getNextNodeID() {
        return nextNodeID;
    }
}
