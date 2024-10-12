package com.blockport;

import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.contract.ContractInterface;
import org.hyperledger.fabric.contract.annotation.Contract;
import org.hyperledger.fabric.contract.annotation.Default;
import org.hyperledger.fabric.contract.annotation.Transaction;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;
//import org.hyperledger.fabric.contract.annotation.Constructor;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ChaincodeBase;

import java.util.Map;
import java.util.logging.Logger;

@Contract(name = "MyAssetContract")
@Default
public class Main implements ContractInterface {

    private final static Logger logger = Logger.getLogger(Main.class.getName());

    // Create an asset
    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void createAsset(final Context ctx, String assetId, String value) {
        ChaincodeStub stub = ctx.getStub();

        String asset = stub.getStringState(assetId);
        if (asset != null && !asset.isEmpty()) {
            throw new RuntimeException("Asset " + assetId + " already exists");
        }

        stub.putStringState(assetId, value);
    }

    // Retrieve an asset
    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public String readAsset(final Context ctx, String assetId) {
        ChaincodeStub stub = ctx.getStub();
        String asset = stub.getStringState(assetId);

        if (asset == null || asset.isEmpty()) {
            throw new RuntimeException("Asset " + assetId + " does not exist");
        }

        return asset;
    }

    // Update an asset
    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void updateAsset(final Context ctx, String assetId, String newValue) {
        ChaincodeStub stub = ctx.getStub();
        String asset = stub.getStringState(assetId);

        if (asset == null || asset.isEmpty()) {
            throw new RuntimeException("Asset " + assetId + " does not exist");
        }

        stub.putStringState(assetId, newValue);
    }

    // Delete an asset
    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void deleteAsset(final Context ctx, String assetId) {
        ChaincodeStub stub = ctx.getStub();
        String asset = stub.getStringState(assetId);

        if (asset == null || asset.isEmpty()) {
            throw new RuntimeException("Asset " + assetId + " does not exist");
        }

        stub.delState(assetId);
    }
}