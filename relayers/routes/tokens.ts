import {Router} from 'express';
import supportedTokens from "../res/supportedTokens.json"

const router = Router();

router.get("/", (req, res) => {
    // read supported tokens from JSON file
    res.json(supportedTokens);
});

export default router;