package com.blockport;

import com.owlike.genson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.util.List;


@DataType()
public class Shipment {
    @Property
    private final String shipmentID;
    @Property
    private final List<String> route;
    @Property
    private final int currentNode;
    @Property
    private final String description;

    public Shipment(@JsonProperty String shipmentID, @JsonProperty("route") List<String> route,
                    @JsonProperty("currentNode") int currentNode, @JsonProperty String description) {
        this.route = List.copyOf(route);
        this.currentNode = currentNode;
        this.shipmentID = shipmentID;
        this.description = description;
    }

    public List<String> getRoute() {
        return List.copyOf(route);
    }

    public int getCurrentNode() {
        return currentNode;
    }

    public String getShipmentID() {
        return shipmentID;
    }

    public String getDescription() {
        return description;
    }
}
