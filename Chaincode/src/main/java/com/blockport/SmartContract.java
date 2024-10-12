package com.blockport;

import com.owlike.genson.Genson;
import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.contract.ContractInterface;
import org.hyperledger.fabric.contract.annotation.Contract;
import org.hyperledger.fabric.contract.annotation.Default;
import org.hyperledger.fabric.contract.annotation.Transaction;
import org.hyperledger.fabric.shim.ChaincodeException;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ledger.KeyModification;
import org.hyperledger.fabric.shim.ledger.KeyValue;
import org.hyperledger.fabric.shim.ledger.QueryResultsIterator;

import java.io.IOException;
import java.security.cert.CertificateException;
import java.util.List;


@Contract(
        name = "contract"
)
@Default
public class SmartContract implements ContractInterface {
    private final Genson genson = new Genson();

    private enum AssetTransferErrors {
        ASSET_NOT_FOUND,
        ASSET_ALREADY_EXISTS
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void init(final Context ctx) {
        ChaincodeStub stub = ctx.getStub();

        IDCounter c = new IDCounter(0, 0);

        stub.putStringState("counter", genson.serialize(c));
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public IDCounter getCounter(final Context ctx) {
        ChaincodeStub stub = ctx.getStub();
        return genson.deserialize(stub.getStringState("counter"), IDCounter.class);
    }


    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void createNode(final Context ctx) throws CertificateException, IOException {
        ChaincodeStub stub = ctx.getStub();
        IDCounter c = getCounter(ctx);
        int nodeID = c.getNextNodeID();
        stub.putStringState("counter", genson.serialize(new IDCounter(c.getNextShipmentID(), nodeID + 1)));

        String mspid = stub.getStringState("mspid");

        Node node = new Node("node" + nodeID, mspid.substring(0, mspid.length() - 3));

        stub.putStringState("node" + nodeID, genson.serialize(node));
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public Node getNode(final Context ctx, String nodeID) {
        ChaincodeStub stub = ctx.getStub();
        if (!AssetExists(ctx, nodeID)) {
            throw new ChaincodeException("Node " + nodeID + " does not exist");
        }
        return genson.deserialize(stub.getStringState(nodeID), Node.class);
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void createShipment(final Context ctx, String description, String... nodes) throws CertificateException, IOException {
        if (nodes.length == 0) {
            throw new ChaincodeException("Shipment must traverse at least 2 locations!");
        }
        for (String node : nodes) {
            if (!AssetExists(ctx, node)) {
                throw new ChaincodeException("Node " + node + " does not exist");
            }
        }
        ChaincodeStub stub = ctx.getStub();
        IDCounter c = getCounter(ctx);
        int shipmentID = c.getNextShipmentID();
        stub.putStringState("counter", genson.serialize(new IDCounter(shipmentID + 1, c.getNextNodeID())));

        String mspid = stub.getStringState("mspid");
        Node first = getNode(ctx, nodes[0]);
        if (!first.getOwnerOrg().equals(mspid.substring(0, mspid.length() - 3))) {
            throw new ChaincodeException("Shipment must be created by the organization of the shipper!");
        }
        Shipment shipment = new Shipment("shipment" + shipmentID, List.of(nodes), 0, description);
        stub.putStringState("shipment" + shipmentID, genson.serialize(shipment));
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public Shipment getShipment(final Context ctx, String shipmentID) {
        ChaincodeStub stub = ctx.getStub();
        if (!AssetExists(ctx, shipmentID)) {
            throw new ChaincodeException("Shipment " + shipmentID + " does not exist");
        }
        return genson.deserialize(stub.getStringState(shipmentID), Shipment.class);
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void advanceShipment(final Context ctx, String shipmentID) {
        ChaincodeStub stub = ctx.getStub();
        if (!AssetExists(ctx, shipmentID)) {
            throw new ChaincodeException("Shipment " + shipmentID + " does not exist");
        }
        Shipment shipment = getShipment(ctx, shipmentID);
        int nextNode = shipment.getCurrentNode() + 1;
        if (nextNode == shipment.getRoute().size() - 1) {
            deleteShipment(ctx, shipmentID);  // reached destination
        } else {
            nextNode++;
            String mspid = stub.getStringState("mspid");
            Node node = getNode(ctx, shipment.getRoute().get(nextNode));
            if (!node.getOwnerOrg().equals(mspid.substring(0, mspid.length() - 3))) {
                throw new ChaincodeException("Update must be done by the next org!");
            }
            stub.putStringState(shipmentID, genson.serialize(new Shipment(shipmentID, shipment.getRoute(), nextNode, shipment.getDescription())));
        }
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public String getAllAssets(final Context ctx) {
        ChaincodeStub stub = ctx.getStub();
        // To retrieve all assets from the ledger use getStateByRange with empty startKey & endKey.
        // Giving empty startKey & endKey is interpreted as all the keys from beginning to end.
        // As another example, if you use startKey = 'asset0', endKey = 'asset9' ,
        // then getStateByRange will retrieve asset with keys between asset0 (inclusive) and asset9 (exclusive) in lexical order.
        StringBuilder res = new StringBuilder("{");
        QueryResultsIterator<KeyValue> results = stub.getStateByRange("", "");

        for (KeyValue result: results) {
            res.append(result.getStringValue());
        }

        return res.toString();
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public String GetAssetHistory(final Context ctx, final String assetID) {
        ChaincodeStub stub = ctx.getStub();

        // Get the history for the asset by assetID
        QueryResultsIterator<KeyModification> history = stub.getHistoryForKey(assetID);

        StringBuilder historyResponse = new StringBuilder();
        historyResponse.append("[");

        // Iterate over the history and construct the response
        for (KeyModification modification : history) {
            if (historyResponse.length() > 1) {
                historyResponse.append(",");
            }
            historyResponse.append("{");
            historyResponse.append("\"txId\":\"").append(modification.getTxId()).append("\",");
            historyResponse.append("\"value\":\"").append(modification.getStringValue()).append("\",");
            historyResponse.append("\"timestamp\":\"").append(modification.getTimestamp()).append("\",");
            historyResponse.append("\"isDeleted\":").append(modification.isDeleted());
            historyResponse.append("}");
        }

        historyResponse.append("]");

        // Return the history as a JSON string
        return historyResponse.toString();
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void deleteShipment(final Context ctx, String shipmentID) {
        ChaincodeStub stub = ctx.getStub();
        if (!AssetExists(ctx, shipmentID)) {
            throw new ChaincodeException("Shipment " + shipmentID + " does not exist");
        }
        stub.delState(shipmentID);
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public boolean AssetExists(final Context ctx, final String assetID) {
        ChaincodeStub stub = ctx.getStub();
        String assetJSON = stub.getStringState(assetID);

        return (assetJSON != null && !assetJSON.isEmpty());
    }
}
