// SPDX-License-Identifier: GPL-2.0
/*
 * mt7981b_ppe - MT7981B (Filogic 820) packet processing engine hook, prototype.
 *
 * Goal: attach the PPE flow table to the WED path so wireless offload traffic
 * on the filogic target goes through the same PPE entries as the wired path.
 *
 * Status: compiles, does not link. mtk_wed_device_attach() and
 * mtk_ppe_wed_bind() are referenced directly below (MT7981B_WED_DIRECT_CALLS),
 * but the target kernel image does not export them, see logs/.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/netdevice.h>
#include <linux/of.h>
#include <linux/of_platform.h>
#include <linux/slab.h>

#define DRV_NAME	"mt7981b_ppe"
#define DRV_VERSION	"0.1.0"

struct mt7981b_ppe_priv {
	struct device		*dev;
	struct net_device	*ndev;
	bool			attached;
};

static struct mt7981b_ppe_priv *g_priv;

#ifdef MT7981B_WED_DIRECT_CALLS
/*
 * Straight symbol dependency. This is what fails at modpost: the objects are
 * built into the kernel image but without EXPORT_SYMBOL() when
 * CONFIG_NET_MEDIATEK_SOC_WED is off, so nothing appears in Module.symvers.
 */
extern int mtk_wed_device_attach(struct device *dev);
extern int mtk_ppe_wed_bind(void *ppe, void *wed);
#endif

static int mt7981b_ppe_probe(struct platform_device *pdev)
{
	struct mt7981b_ppe_priv *priv;
	int ret = 0;

	priv = devm_kzalloc(&pdev->dev, sizeof(*priv), GFP_KERNEL);
	if (!priv)
		return -ENOMEM;

	priv->dev = &pdev->dev;
	platform_set_drvdata(pdev, priv);

	dev_info(priv->dev, "%s %s: attaching PPE hooks\n", DRV_NAME, DRV_VERSION);

#ifdef MT7981B_WED_DIRECT_CALLS
	ret = mtk_wed_device_attach(priv->dev);
	if (ret) {
		dev_err(priv->dev, "wed attach failed: %d\n", ret);
		return ret;
	}

	ret = mtk_ppe_wed_bind(NULL, NULL);
	if (ret) {
		dev_err(priv->dev, "ppe/wed bind failed: %d\n", ret);
		return ret;
	}
#endif

	priv->attached = true;
	g_priv = priv;

	return 0;
}

static int mt7981b_ppe_remove(struct platform_device *pdev)
{
	struct mt7981b_ppe_priv *priv = platform_get_drvdata(pdev);

	dev_info(priv->dev, "%s: detaching\n", DRV_NAME);
	priv->attached = false;
	g_priv = NULL;

	return 0;
}

static const struct of_device_id mt7981b_ppe_of_match[] = {
	{ .compatible = "mediatek,mt7981-ppe" },
	{ /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, mt7981b_ppe_of_match);

static struct platform_driver mt7981b_ppe_driver = {
	.probe	= mt7981b_ppe_probe,
	.remove	= mt7981b_ppe_remove,
	.driver	= {
		.name		= DRV_NAME,
		.of_match_table	= mt7981b_ppe_of_match,
	},
};

static int __init mt7981b_ppe_init(void)
{
	pr_info("%s: version %s loaded\n", DRV_NAME, DRV_VERSION);
	return platform_driver_register(&mt7981b_ppe_driver);
}

static void __exit mt7981b_ppe_exit(void)
{
	platform_driver_unregister(&mt7981b_ppe_driver);
}

module_init(mt7981b_ppe_init);
module_exit(mt7981b_ppe_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("xbyyd");
MODULE_DESCRIPTION("MT7981B PPE/WED hook prototype");
MODULE_VERSION(DRV_VERSION);
